import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_wgpu/flutter_wgpu.dart';

/// GPU surface that manages a platform texture for rendering.
///
/// Wraps [WgpuTextureController] and handles resize with coalescing —
/// safe to call [requestResize] rapidly from build. Resizes immediately
/// and calls [onResized] so the caller can render into the new texture
/// before the next vsync.
///
/// Created via [GpuSurface.create]. Dispose when done.
///
/// ```dart
/// final surface = await GpuSurface.create(device: controller.device);
/// // ... pass to GpuView ...
/// surface.dispose();
/// ```
class GpuSurface {
  GpuSurface._(this._controller);

  /// Fallback size when actual dimensions aren't known yet.
  static const _fallbackSize = 64;

  static Future<GpuSurface> create({
    required GpuDevice device,
    int? width,
    int? height,
  }) async {
    final controller = WgpuTextureController(
      deviceHandle: (device as WgpuDevice).handle,
      width: width ?? _fallbackSize,
      height: height ?? _fallbackSize,
    );
    await controller.initialize();
    return GpuSurface._(controller);
  }

  final WgpuTextureController _controller;
  int _targetWidth = 0;
  int _targetHeight = 0;
  int _lastRequestedWidth = 0;
  int _lastRequestedHeight = 0;
  bool _resizing = false;
  bool _disposed = false;

  /// Flutter texture ID for the [Texture] widget.
  int? get textureId => _controller.textureId;

  /// Current surface width in pixels.
  int get width => _controller.width;

  /// Current surface height in pixels.
  int get height => _controller.height;

  /// Actual texture format of this surface.
  GpuTextureFormat get format => _controller.surface!.format;

  /// The current texture view to render into.
  GpuTextureView get textureView => _controller.surface!.textureView;

  /// Whether the surface is ready for rendering.
  bool get isReady => _controller.isSurfaceReady;

  /// The underlying controller (for [WgpuTextureWidget]).
  WgpuTextureController get controller => _controller;

  /// Called after each resize step completes. Render a frame here
  /// to fill the new texture before the next vsync.
  VoidCallback? onResized;

  /// Request a resize to the given pixel dimensions.
  ///
  /// Resizes immediately. If a resize is already in progress,
  /// the new target is remembered and applied when the current
  /// resize finishes (coalescing).
  void requestResize(int w, int h) {
    if (_disposed || w <= 0 || h <= 0) return;
    _targetWidth = w;
    _targetHeight = h;
    if (w == _lastRequestedWidth && h == _lastRequestedHeight) return;
    if (!_resizing) _doResize();
  }

  Future<void> _doResize() async {
    _resizing = true;
    try {
      while (!_disposed &&
          (_targetWidth != _lastRequestedWidth ||
              _targetHeight != _lastRequestedHeight)) {
        final w = _targetWidth;
        final h = _targetHeight;
        await _controller.resize(w, h);
        if (_disposed) return;
        _lastRequestedWidth = w;
        _lastRequestedHeight = h;
        onResized?.call();
      }
    } finally {
      _resizing = false;
    }
  }

  /// Present the current frame (call after rendering).
  void present() {
    if (_disposed) return;
    final surface = _controller.surface!;
    surface.present();
    if (!Platform.isAndroid) {
      _controller.markFrameAvailableSync();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    onResized = null;
    _controller.dispose();
  }
}
