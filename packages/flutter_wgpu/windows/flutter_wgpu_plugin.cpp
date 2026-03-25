// Flutter texture sharing plugin for wgpu surfaces.
//
// Supports two paths:
// 1. GpuSurfaceTexture: D3D11 shared handle (GPU-GPU, zero-copy)
//    DISABLED: Flutter 3.41.1's ANGLE rejects eglCreatePbufferFromClientBuffer
//    with EGL_TEXTURE_FORMAT=RGBA (no config has EGL_BIND_TO_TEXTURE_RGBA).
//    See docs/flutter-texture-sharing-investigation.txt
// 2. PixelBuffer: CPU pixel buffer (current active path)

#include "include/flutter_wgpu/flutter_wgpu_plugin_c_api.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>

#include <windows.h>

#include <map>
#include <memory>
#include <iostream>

namespace flutter_wgpu {

// Base class for texture holders
class TextureHolderBase {
public:
    virtual ~TextureHolderBase() = default;
    virtual void MarkFrameAvailable() = 0;
    virtual int64_t texture_id() const = 0;
    virtual void UpdateBuffer(const uint8_t* buffer, int width, int height) {
        // Default no-op for GPU surface textures
    }
};

// Pixel buffer texture holder
class PixelBufferTextureHolder : public TextureHolderBase {
public:
    PixelBufferTextureHolder(
        flutter::TextureRegistrar* registrar,
        const uint8_t* pixel_buffer_ptr,
        int width,
        int height
    ) : texture_registrar_(registrar),
        pixel_buffer_ptr_(pixel_buffer_ptr),
        width_(width),
        height_(height) {

        pixel_buffer_ = std::make_unique<FlutterDesktopPixelBuffer>();
        pixel_buffer_->width = width_;
        pixel_buffer_->height = height_;
        pixel_buffer_->buffer = pixel_buffer_ptr_;

        flutter_texture_ = std::make_unique<flutter::TextureVariant>(
            flutter::PixelBufferTexture(
                [this](size_t width, size_t height) -> const FlutterDesktopPixelBuffer* {
                    return pixel_buffer_.get();
                }
            )
        );

        texture_id_ = texture_registrar_->RegisterTexture(flutter_texture_.get());
        std::cerr << "flutter_wgpu: Registered PixelBuffer texture " << texture_id_
                  << " (" << width_ << "x" << height_ << ")" << std::endl;
    }

    ~PixelBufferTextureHolder() override {
        if (texture_id_ >= 0) {
            texture_registrar_->UnregisterTexture(texture_id_);
        }
    }

    void UpdateBuffer(const uint8_t* pixel_buffer_ptr, int width, int height) override {
        pixel_buffer_ptr_ = pixel_buffer_ptr;
        width_ = width;
        height_ = height;

        pixel_buffer_->width = width_;
        pixel_buffer_->height = height_;
        pixel_buffer_->buffer = pixel_buffer_ptr_;
    }

    void MarkFrameAvailable() override {
        texture_registrar_->MarkTextureFrameAvailable(texture_id_);
    }

    int64_t texture_id() const override { return texture_id_; }

private:
    flutter::TextureRegistrar* texture_registrar_;
    const uint8_t* pixel_buffer_ptr_;
    int width_;
    int height_;
    int64_t texture_id_ = -1;
    std::unique_ptr<FlutterDesktopPixelBuffer> pixel_buffer_;
    std::unique_ptr<flutter::TextureVariant> flutter_texture_;
};

// GPU surface texture holder (DISABLED — see file header comment).
// Kept for when Flutter fixes the ANGLE EGL config regression.
class GpuSurfaceTextureHolder : public TextureHolderBase {
public:
    GpuSurfaceTextureHolder(
        flutter::TextureRegistrar* registrar,
        void* shared_handle,
        int width,
        int height
    ) : texture_registrar_(registrar),
        shared_handle_(shared_handle),
        width_(width),
        height_(height) {

        gpu_surface_desc_ = std::make_unique<FlutterDesktopGpuSurfaceDescriptor>();
        gpu_surface_desc_->struct_size = sizeof(FlutterDesktopGpuSurfaceDescriptor);
        gpu_surface_desc_->handle = shared_handle_;
        gpu_surface_desc_->width = static_cast<size_t>(width_);
        gpu_surface_desc_->height = static_cast<size_t>(height_);
        gpu_surface_desc_->visible_width = static_cast<size_t>(width_);
        gpu_surface_desc_->visible_height = static_cast<size_t>(height_);
        gpu_surface_desc_->format = kFlutterDesktopPixelFormatBGRA8888;
        gpu_surface_desc_->release_callback = nullptr;
        gpu_surface_desc_->release_context = nullptr;

        flutter_texture_ = std::make_unique<flutter::TextureVariant>(
            flutter::GpuSurfaceTexture(
                kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle,
                [this](size_t width, size_t height) -> const FlutterDesktopGpuSurfaceDescriptor* {
                    return gpu_surface_desc_.get();
                }
            )
        );

        texture_id_ = texture_registrar_->RegisterTexture(flutter_texture_.get());
        std::cerr << "flutter_wgpu: Registered GpuSurface texture " << texture_id_
                  << " (" << width_ << "x" << height_ << ")" << std::endl;
    }

    ~GpuSurfaceTextureHolder() override {
        if (texture_id_ >= 0) {
            texture_registrar_->UnregisterTexture(texture_id_);
        }
    }

    void MarkFrameAvailable() override {
        texture_registrar_->MarkTextureFrameAvailable(texture_id_);
    }

    int64_t texture_id() const override { return texture_id_; }

private:
    flutter::TextureRegistrar* texture_registrar_;
    void* shared_handle_;
    int width_;
    int height_;
    int64_t texture_id_ = -1;
    std::unique_ptr<FlutterDesktopGpuSurfaceDescriptor> gpu_surface_desc_;
    std::unique_ptr<flutter::TextureVariant> flutter_texture_;
};

class FlutterWgpuPlugin : public flutter::Plugin {
public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

    FlutterWgpuPlugin(flutter::TextureRegistrar* texture_registrar);
    virtual ~FlutterWgpuPlugin();

    FlutterWgpuPlugin(const FlutterWgpuPlugin&) = delete;
    FlutterWgpuPlugin& operator=(const FlutterWgpuPlugin&) = delete;

private:
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
    );

    void HandleRegisterTexture(
        const flutter::EncodableMap& args,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
    );

    void HandleUnregisterTexture(
        const flutter::EncodableMap& args,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
    );

    void HandleMarkFrameAvailable(
        const flutter::EncodableMap& args,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
    );

    void HandleUpdateTexture(
        const flutter::EncodableMap& args,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
    );

    flutter::TextureRegistrar* texture_registrar_;
    std::map<int64_t, std::unique_ptr<TextureHolderBase>> textures_;
};

void FlutterWgpuPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
    auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(),
        "flutter_wgpu",
        &flutter::StandardMethodCodec::GetInstance()
    );

    auto plugin = std::make_unique<FlutterWgpuPlugin>(registrar->texture_registrar());

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto& call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        }
    );

    registrar->AddPlugin(std::move(plugin));
}

FlutterWgpuPlugin::FlutterWgpuPlugin(flutter::TextureRegistrar* texture_registrar)
    : texture_registrar_(texture_registrar) {}

FlutterWgpuPlugin::~FlutterWgpuPlugin() {}

void FlutterWgpuPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
) {
    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());

    if (method_call.method_name() == "registerTexture") {
        if (!args) {
            result->Error("INVALID_ARGS", "Missing arguments");
            return;
        }
        HandleRegisterTexture(*args, std::move(result));
    } else if (method_call.method_name() == "unregisterTexture") {
        if (!args) {
            result->Error("INVALID_ARGS", "Missing arguments");
            return;
        }
        HandleUnregisterTexture(*args, std::move(result));
    } else if (method_call.method_name() == "markFrameAvailable") {
        if (!args) {
            result->Error("INVALID_ARGS", "Missing arguments");
            return;
        }
        HandleMarkFrameAvailable(*args, std::move(result));
    } else if (method_call.method_name() == "updateTexture") {
        if (!args) {
            result->Error("INVALID_ARGS", "Missing arguments");
            return;
        }
        HandleUpdateTexture(*args, std::move(result));
    } else {
        result->NotImplemented();
    }
}

void FlutterWgpuPlugin::HandleRegisterTexture(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
) {
    auto width_it = args.find(flutter::EncodableValue("width"));
    auto height_it = args.find(flutter::EncodableValue("height"));

    if (width_it == args.end() || height_it == args.end()) {
        result->Error("INVALID_ARGS", "Missing width or height");
        return;
    }

    int width = std::get<int32_t>(width_it->second);
    int height = std::get<int32_t>(height_it->second);

    // Check for shared handle (GPU surface path — currently disabled)
    auto shared_handle_it = args.find(flutter::EncodableValue("sharedHandle"));
    if (shared_handle_it != args.end()) {
        int64_t handle_value = std::get<int64_t>(shared_handle_it->second);
        if (handle_value != 0) {
            void* shared_handle = reinterpret_cast<void*>(handle_value);
            auto holder = std::make_unique<GpuSurfaceTextureHolder>(
                texture_registrar_,
                shared_handle,
                width,
                height
            );

            int64_t texture_id = holder->texture_id();
            if (texture_id < 0) {
                result->Error("TEXTURE_FAILED", "Failed to register GPU surface texture");
                return;
            }

            textures_[texture_id] = std::move(holder);
            result->Success(flutter::EncodableValue(texture_id));
            return;
        }
    }

    // Pixel buffer path
    auto pixel_buffer_ptr_it = args.find(flutter::EncodableValue("pixelBufferPtr"));
    if (pixel_buffer_ptr_it == args.end()) {
        pixel_buffer_ptr_it = args.find(flutter::EncodableValue("platformHandle"));
    }

    if (pixel_buffer_ptr_it == args.end()) {
        result->Error("INVALID_ARGS", "Missing sharedHandle and pixelBufferPtr");
        return;
    }

    int64_t ptr_value = std::get<int64_t>(pixel_buffer_ptr_it->second);
    const uint8_t* pixel_buffer_ptr = reinterpret_cast<const uint8_t*>(ptr_value);

    auto holder = std::make_unique<PixelBufferTextureHolder>(
        texture_registrar_,
        pixel_buffer_ptr,
        width,
        height
    );

    int64_t texture_id = holder->texture_id();
    if (texture_id < 0) {
        result->Error("TEXTURE_FAILED", "Failed to register pixel buffer texture");
        return;
    }

    textures_[texture_id] = std::move(holder);
    result->Success(flutter::EncodableValue(texture_id));
}

void FlutterWgpuPlugin::HandleUnregisterTexture(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
) {
    auto texture_id_it = args.find(flutter::EncodableValue("textureId"));
    if (texture_id_it == args.end()) {
        result->Error("INVALID_ARGS", "Missing textureId");
        return;
    }

    int64_t texture_id = std::get<int64_t>(texture_id_it->second);
    textures_.erase(texture_id);
    result->Success();
}

void FlutterWgpuPlugin::HandleMarkFrameAvailable(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
) {
    auto texture_id_it = args.find(flutter::EncodableValue("textureId"));
    if (texture_id_it == args.end()) {
        result->Error("INVALID_ARGS", "Missing textureId");
        return;
    }

    int64_t texture_id = std::get<int64_t>(texture_id_it->second);
    auto it = textures_.find(texture_id);
    if (it != textures_.end()) {
        it->second->MarkFrameAvailable();
    }
    result->Success();
}

void FlutterWgpuPlugin::HandleUpdateTexture(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
) {
    auto texture_id_it = args.find(flutter::EncodableValue("textureId"));
    auto pixel_buffer_ptr_it = args.find(flutter::EncodableValue("pixelBufferPtr"));
    auto width_it = args.find(flutter::EncodableValue("width"));
    auto height_it = args.find(flutter::EncodableValue("height"));

    if (pixel_buffer_ptr_it == args.end()) {
        pixel_buffer_ptr_it = args.find(flutter::EncodableValue("platformHandle"));
    }

    if (texture_id_it == args.end() || pixel_buffer_ptr_it == args.end() ||
        width_it == args.end() || height_it == args.end()) {
        result->Error("INVALID_ARGS", "Missing arguments");
        return;
    }

    int64_t texture_id = std::get<int64_t>(texture_id_it->second);
    int64_t ptr_value = std::get<int64_t>(pixel_buffer_ptr_it->second);
    const uint8_t* pixel_buffer_ptr = reinterpret_cast<const uint8_t*>(ptr_value);
    int width = std::get<int32_t>(width_it->second);
    int height = std::get<int32_t>(height_it->second);

    auto it = textures_.find(texture_id);
    if (it != textures_.end()) {
        it->second->UpdateBuffer(pixel_buffer_ptr, width, height);
    }
    result->Success();
}

}  // namespace flutter_wgpu

void FlutterWgpuPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar
) {
    flutter_wgpu::FlutterWgpuPlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarManager::GetInstance()
            ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar)
    );
}
