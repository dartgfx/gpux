// Flutter texture sharing plugin for wgpu surfaces (Linux).
//
// Uses pixel buffer path: wgpu renders to CPU buffer, Flutter reads it via
// FlPixelBufferTexture's copy_pixels callback.

#include "include/flutter_wgpu/flutter_wgpu_plugin.h"

#include <flutter_linux/flutter_linux.h>

#include <cstring>
#include <map>
#include <memory>
#include <iostream>

// =============================================================================
// WgpuPixelBufferTexture — FlPixelBufferTexture subclass
// =============================================================================

struct _WgpuPixelBufferTexture {
  FlPixelBufferTexture parent_instance;
  const uint8_t* pixel_buffer_ptr;
  int width;
  int height;
};

#define WGPU_TYPE_PIXEL_BUFFER_TEXTURE (wgpu_pixel_buffer_texture_get_type())
G_DECLARE_FINAL_TYPE(WgpuPixelBufferTexture, wgpu_pixel_buffer_texture,
                     WGPU, PIXEL_BUFFER_TEXTURE, FlPixelBufferTexture)
G_DEFINE_TYPE(WgpuPixelBufferTexture, wgpu_pixel_buffer_texture,
              fl_pixel_buffer_texture_get_type())

static gboolean wgpu_pixel_buffer_texture_copy_pixels(
    FlPixelBufferTexture* texture,
    const uint8_t** out_buffer,
    uint32_t* width,
    uint32_t* height,
    GError** error) {
  WgpuPixelBufferTexture* self = WGPU_PIXEL_BUFFER_TEXTURE(texture);

  *out_buffer = self->pixel_buffer_ptr;
  *width = self->width;
  *height = self->height;

  return TRUE;
}

static void wgpu_pixel_buffer_texture_class_init(
    WgpuPixelBufferTextureClass* klass) {
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels =
      wgpu_pixel_buffer_texture_copy_pixels;
}

static void wgpu_pixel_buffer_texture_init(WgpuPixelBufferTexture* self) {
  self->pixel_buffer_ptr = nullptr;
  self->width = 0;
  self->height = 0;
}

static WgpuPixelBufferTexture* wgpu_pixel_buffer_texture_new(
    const uint8_t* buffer_ptr, int width, int height) {
  WgpuPixelBufferTexture* self = WGPU_PIXEL_BUFFER_TEXTURE(
      g_object_new(WGPU_TYPE_PIXEL_BUFFER_TEXTURE, nullptr));
  self->pixel_buffer_ptr = buffer_ptr;
  self->width = width;
  self->height = height;
  return self;
}

// =============================================================================
// Plugin implementation
// =============================================================================

struct TextureEntry {
  WgpuPixelBufferTexture* texture;
  int64_t texture_id;
};

static FlTextureRegistrar* texture_registrar_ = nullptr;
static std::map<int64_t, TextureEntry> textures_;

static FlMethodResponse* handle_register_texture(FlValue* args) {
  FlValue* width_v = fl_value_lookup_string(args, "width");
  FlValue* height_v = fl_value_lookup_string(args, "height");
  FlValue* ptr_v = fl_value_lookup_string(args, "pixelBufferPtr");
  if (!ptr_v) {
    ptr_v = fl_value_lookup_string(args, "platformHandle");
  }

  if (!width_v || !height_v || !ptr_v) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGS", "Missing width, height, or pixelBufferPtr", nullptr));
  }

  int width = fl_value_get_int(width_v);
  int height = fl_value_get_int(height_v);
  int64_t ptr_value = fl_value_get_int(ptr_v);
  const uint8_t* pixel_buffer_ptr = reinterpret_cast<const uint8_t*>(ptr_value);

  WgpuPixelBufferTexture* texture =
      wgpu_pixel_buffer_texture_new(pixel_buffer_ptr, width, height);

  gboolean registered = fl_texture_registrar_register_texture(
      texture_registrar_, FL_TEXTURE(texture));
  if (!registered) {
    g_object_unref(texture);
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "TEXTURE_FAILED", "Failed to register pixel buffer texture", nullptr));
  }

  int64_t texture_id = fl_texture_get_id(FL_TEXTURE(texture));
  textures_[texture_id] = {texture, texture_id};

  std::cerr << "flutter_wgpu: Registered PixelBuffer texture " << texture_id
            << " (" << width << "x" << height << ")" << std::endl;

  g_autoptr(FlValue) result = fl_value_new_int(texture_id);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse* handle_unregister_texture(FlValue* args) {
  FlValue* id_v = fl_value_lookup_string(args, "textureId");
  if (!id_v) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGS", "Missing textureId", nullptr));
  }

  int64_t texture_id = fl_value_get_int(id_v);
  auto it = textures_.find(texture_id);
  if (it != textures_.end()) {
    fl_texture_registrar_unregister_texture(
        texture_registrar_, FL_TEXTURE(it->second.texture));
    g_object_unref(it->second.texture);
    textures_.erase(it);
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

static FlMethodResponse* handle_mark_frame_available(FlValue* args) {
  FlValue* id_v = fl_value_lookup_string(args, "textureId");
  if (!id_v) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGS", "Missing textureId", nullptr));
  }

  int64_t texture_id = fl_value_get_int(id_v);
  auto it = textures_.find(texture_id);
  if (it != textures_.end()) {
    fl_texture_registrar_mark_texture_frame_available(
        texture_registrar_, FL_TEXTURE(it->second.texture));
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

static FlMethodResponse* handle_update_texture(FlValue* args) {
  FlValue* id_v = fl_value_lookup_string(args, "textureId");
  FlValue* ptr_v = fl_value_lookup_string(args, "pixelBufferPtr");
  FlValue* width_v = fl_value_lookup_string(args, "width");
  FlValue* height_v = fl_value_lookup_string(args, "height");

  if (!ptr_v) {
    ptr_v = fl_value_lookup_string(args, "platformHandle");
  }

  if (!id_v || !ptr_v || !width_v || !height_v) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGS", "Missing arguments", nullptr));
  }

  int64_t texture_id = fl_value_get_int(id_v);
  int64_t ptr_value = fl_value_get_int(ptr_v);
  int width = fl_value_get_int(width_v);
  int height = fl_value_get_int(height_v);

  auto it = textures_.find(texture_id);
  if (it != textures_.end()) {
    it->second.texture->pixel_buffer_ptr =
        reinterpret_cast<const uint8_t*>(ptr_value);
    it->second.texture->width = width;
    it->second.texture->height = height;
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

static void method_call_handler(FlMethodChannel* channel,
                                FlMethodCall* method_call,
                                gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(method, "registerTexture") == 0) {
    response = handle_register_texture(args);
  } else if (strcmp(method, "unregisterTexture") == 0) {
    response = handle_unregister_texture(args);
  } else if (strcmp(method, "markFrameAvailable") == 0) {
    response = handle_mark_frame_available(args);
  } else if (strcmp(method, "updateTexture") == 0) {
    response = handle_update_texture(args);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

// =============================================================================
// Plugin registration
// =============================================================================

void flutter_wgpu_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  texture_registrar_ =
      fl_plugin_registrar_get_texture_registrar(registrar);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "flutter_wgpu",
      FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      channel, method_call_handler, nullptr, nullptr);
}
