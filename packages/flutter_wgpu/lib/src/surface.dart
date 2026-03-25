import 'dart:ffi';

import 'package:wgpu/wgpu.dart';
import 'package:wgpu/wgpu_ffi.dart' as ffi;
import 'package:wgpu/wgpu_ffi.dart' show wgpuLastError, textureFormatFromFfi;

/// A render surface for Flutter display.
class WgpuSurface implements WgpuResource {
  WgpuSurface._(this._id, this._width, this._height);

  /// Create a render surface (Apple/Windows).
  factory WgpuSurface.create({
    required int deviceHandle,
    required int width,
    required int height,
  }) {
    final id = ffi.wgpu_create_surface(deviceHandle, width, height);
    if (id == 0) {
      throw StateError('Failed to create surface: ${wgpuLastError()}');
    }
    return WgpuSurface._(id, width, height);
  }

  /// Create a surface from a native window handle (Android only).
  ///
  /// [windowPtr]: ANativeWindow pointer from Flutter's Surface
  factory WgpuSurface.createFromWindow({
    required int deviceHandle,
    required int windowPtr,
    required int width,
    required int height,
  }) {
    final ptr = Pointer<Void>.fromAddress(windowPtr);
    final id = ffi.wgpu_create_surface_from_window(
      deviceHandle,
      ptr,
      width,
      height,
    );
    if (id == 0) {
      throw StateError(
        'Failed to create surface from window: ${wgpuLastError()}',
      );
    }
    return WgpuSurface._(id, width, height);
  }

  final int _id;
  int _width;
  int _height;
  WgpuTextureView? _cachedView;
  bool _disposed = false;

  @override
  bool get isDisposed => _disposed;

  /// Surface ID.
  int get id => _id;

  /// Width in pixels.
  int get width => _width;

  /// Height in pixels.
  int get height => _height;

  /// Texture format of this surface.
  GpuTextureFormat get format =>
      textureFormatFromFfi(ffi.wgpu_get_surface_format(_id));

  /// Platform handle for Flutter Texture widget registration.
  /// macOS/iOS: IOSurfaceID
  /// Windows: 0 (use pixelBufferPtr instead)
  int get platformHandle => ffi.wgpu_get_surface_handle(_id);

  /// Pixel buffer pointer (Windows only).
  int get pixelBufferPtr => ffi.wgpu_get_pixel_buffer_ptr(_id).address;

  /// D3D11 shared handle (Windows only).
  /// Returns 0 if shared texture is not available.
  int get sharedHandle => ffi.wgpu_get_shared_handle(_id);

  /// Get texture view for rendering.
  ///
  /// Returns a view that can be used as color attachment in render pass.
  /// View is cached per frame - call [present] to invalidate and get next frame's view.
  /// The cached view is automatically disposed when [present], [resize], or [dispose] is called.
  WgpuTextureView get textureView {
    if (_cachedView != null && !_cachedView!.isDisposed) {
      return _cachedView!;
    }

    final handle = ffi.wgpu_surface_get_texture_view(_id);
    if (handle == 0) {
      throw StateError('Failed to get surface texture view');
    }
    _cachedView = WgpuTextureView.internal(handle);
    return _cachedView!;
  }

  /// Copy from another texture to this surface.
  ///
  /// Use this for multi-pass rendering where you render to an offscreen
  /// texture first, then copy the result to the surface for display.
  void copyFrom(WgpuTexture source) {
    ffi.wgpu_surface_copy_from_texture(_id, source.handle);
  }

  /// Signal frame is ready for display.
  ///
  /// Platform behavior:
  /// - Apple: Caller must also call markFrameAvailable on Flutter side
  /// - Windows: Copies to pixel buffer for Flutter
  /// - Android: Presents swapchain
  ///
  /// Invalidates cached texture view for next frame.
  void present() {
    ffi.wgpu_surface_present(_id);
    // Invalidate view - on Android the swapchain texture changes
    _cachedView?.dispose();
    _cachedView = null;
  }

  /// Resize surface.
  bool resize(int newWidth, int newHeight) {
    if (newWidth == _width && newHeight == _height) return true;

    final result = ffi.wgpu_resize_surface(_id, newWidth, newHeight);
    if (result == 1) {
      _width = newWidth;
      _height = newHeight;
      _cachedView?.dispose();
      _cachedView = null;
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cachedView?.dispose();
    _cachedView = null;
    ffi.wgpu_destroy_surface(_id);
  }
}
