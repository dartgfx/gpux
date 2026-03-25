import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wgpu/wgpu_ffi.dart' as ffi;

import 'surface.dart';

const _channel = MethodChannel('flutter_wgpu');

/// Controller for wgpu-backed Flutter textures.
///
/// Manages the lifecycle of a GPU surface that can be displayed via
/// Flutter's Texture widget. Extends ChangeNotifier to allow widgets
/// to react to state changes.
///
/// Example:
/// ```dart
/// final controller = WgpuTextureController(deviceHandle: device.handle, width: 640, height: 480);
/// await controller.initialize();
///
/// // Render to surface
/// myRenderer.render(controller.surface!);
///
/// // Display in widget tree
/// WgpuTexture(controller: controller)
/// ```
class WgpuTextureController extends ChangeNotifier {
  WgpuTextureController({
    required int deviceHandle,
    required int width,
    required int height,
  })  : _deviceHandle = deviceHandle,
        _width = _alignTo64(width),
        _height = _alignTo64(height);

  /// Align to 64 bytes for IOSurface/CVPixelBuffer compatibility on Apple.
  static int _alignTo64(int value) =>
      Platform.isIOS || Platform.isMacOS ? (value + 63) & ~63 : value;

  final int _deviceHandle;
  int _width;
  int _height;
  WgpuSurface? _surface;
  int? _textureId;
  int? _windowPtr;
  int? _engineHandle; // For direct FFI path on Apple
  bool _surfaceReady = false;
  bool _disposed = false;

  /// Current width in pixels.
  int get width => _width;

  /// Current height in pixels.
  int get height => _height;

  /// Flutter texture ID for use with Texture widget.
  int? get textureId => _textureId;

  /// GPU surface to render to.
  WgpuSurface? get surface => _surface;

  /// Whether the surface is ready for rendering.
  ///
  /// On Android, this may become false when the app is backgrounded
  /// and true again when resumed.
  bool get isSurfaceReady => _surfaceReady;

  /// Initialize the controller.
  ///
  /// Must be called before rendering. Creates the GPU surface and
  /// registers it with Flutter's texture system.
  ///
  /// Requires that a [WgpuDevice] has been created beforehand.
  Future<void> initialize() async {
    if (_disposed) {
      throw StateError('Cannot initialize disposed controller');
    }

    if (Platform.isAndroid) {
      await _initializeAndroid();
    } else if (Platform.isWindows || Platform.isLinux) {
      await _initializePixelBuffer();
    } else {
      await _initializeApple();
    }
  }

  Future<void> _initializeAndroid() async {
    _channel.setMethodCallHandler(_handlePlatformCallback);

    final result = await _channel.invokeMethod<Map>('createSurface', {
      'width': _width,
      'height': _height,
    });

    if (result == null) {
      throw StateError('Failed to create Android surface');
    }

    _textureId = result['textureId'] as int;
    _windowPtr = result['windowPtr'] as int;

    if (_textureId == null || _windowPtr == 0) {
      throw StateError('Invalid surface creation result');
    }

    try {
      _surface = WgpuSurface.createFromWindow(
        deviceHandle: _deviceHandle,
        windowPtr: _windowPtr!,
        width: _width,
        height: _height,
      );
    } catch (e) {
      await _channel.invokeMethod<void>('destroySurface', {
        'textureId': _textureId,
      });
      _textureId = null;
      rethrow;
    }

    _surfaceReady = true;
    notifyListeners();
  }

  Future<dynamic> _handlePlatformCallback(MethodCall call) async {
    final textureId = call.arguments['textureId'] as int?;
    if (textureId != _textureId) return;

    switch (call.method) {
      case 'onSurfaceAvailable':
        debugPrint('WgpuTextureController: Surface available');
        _surfaceReady = true;
        notifyListeners();

      case 'onSurfaceCleanup':
        debugPrint('WgpuTextureController: Surface cleanup');
        _surfaceReady = false;
        notifyListeners();
    }
  }

  Future<void> _initializeApple() async {
    _surface = WgpuSurface.create(
      deviceHandle: _deviceHandle, width: _width, height: _height,
    );

    // Get engine handle for direct FFI path (bypasses MethodChannel)
    _engineHandle = await _channel.invokeMethod<int>('getEngineHandle');

    _textureId = await _channel.invokeMethod<int>('registerTexture', {
      'platformHandle': _surface!.platformHandle,
      'width': _width,
      'height': _height,
    });

    if (_textureId == null || _textureId == -1) {
      throw StateError('Failed to register texture with Flutter');
    }

    _surfaceReady = true;
    notifyListeners();
  }

  Future<void> _initializePixelBuffer() async {
    _surface = WgpuSurface.create(
      deviceHandle: _deviceHandle, width: _width, height: _height,
    );

    // Try D3D11 shared handle first (GPU surface texture)
    final sharedHandle = _surface!.sharedHandle;
    if (sharedHandle != 0) {
      debugPrint(
          'WgpuTextureController: Using D3D11 shared handle (GPU surface)');
      _textureId = await _channel.invokeMethod<int>('registerTexture', {
        'sharedHandle': sharedHandle,
        'width': _width,
        'height': _height,
      });
    } else {
      // Fallback to pixel buffer (CPU copy)
      debugPrint('WgpuTextureController: Using pixel buffer (CPU fallback)');
      _textureId = await _channel.invokeMethod<int>('registerTexture', {
        'pixelBufferPtr': _surface!.pixelBufferPtr,
        'width': _width,
        'height': _height,
      });
    }

    if (_textureId == null || _textureId == -1) {
      throw StateError('Failed to register texture with Flutter');
    }

    _surfaceReady = true;
    notifyListeners();
  }

  /// Resize the surface.
  ///
  /// Updates both the GPU surface and Flutter texture registration.
  Future<void> resize(int newWidth, int newHeight) async {
    if (_disposed) return;
    if (_surface == null) return;

    // Apply same alignment as constructor
    final alignedWidth = _alignTo64(newWidth);
    final alignedHeight = _alignTo64(newHeight);
    if (alignedWidth == _width && alignedHeight == _height) return;

    if (Platform.isWindows || Platform.isLinux) {
      // Windows pixel buffer: create new surface BEFORE disposing old one.
      // Flutter's raster thread reads the pixel buffer pointer at any time,
      // so the old buffer must stay alive until C++ has the new pointer.
      final oldSurface = _surface;
      _surface = WgpuSurface.create(
        deviceHandle: _deviceHandle,
        width: alignedWidth,
        height: alignedHeight,
      );
      _width = alignedWidth;
      _height = alignedHeight;

      if (_textureId != null) {
        await _channel.invokeMethod<void>('updateTexture', {
          'textureId': _textureId,
          'pixelBufferPtr': _surface!.pixelBufferPtr,
          'width': _width,
          'height': _height,
        });
      }
      oldSurface?.dispose();
    } else if (Platform.isAndroid) {
      // Android GL backend: resize the SurfaceProducer FIRST to get the new
      // ANativeWindow, then recreate the wgpu surface with it.
      _width = alignedWidth;
      _height = alignedHeight;

      if (_textureId != null) {
        final result = await _channel.invokeMethod<Map>('resizeSurface', {
          'textureId': _textureId,
          'width': _width,
          'height': _height,
        });
        final newWindowPtr = result?['windowPtr'] as int?;
        if (newWindowPtr != null && newWindowPtr != 0) {
          _windowPtr = newWindowPtr;
        }
      }

      _surface!.dispose();
      _surface = WgpuSurface.createFromWindow(
        deviceHandle: _deviceHandle,
        windowPtr: _windowPtr!,
        width: _width,
        height: _height,
      );
    } else {
      // Apple uses platformHandle (IOSurface)
      if (!_surface!.resize(alignedWidth, alignedHeight)) {
        throw StateError('Failed to resize surface');
      }
      _width = alignedWidth;
      _height = alignedHeight;

      if (_textureId != null) {
        await _channel.invokeMethod<void>('updateTexture', {
          'textureId': _textureId,
          'platformHandle': _surface!.platformHandle,
          'width': _width,
          'height': _height,
        });
      }
    }

    notifyListeners();
  }

  /// Notify Flutter that a new frame is available.
  ///
  /// Call after rendering to the surface. On Android with SurfaceProducer,
  /// this is handled automatically by the swapchain.
  ///
  /// On Apple platforms, uses direct FFI for ~100x lower latency than
  /// MethodChannel.
  Future<void> markFrameAvailable() async {
    if (_disposed) return;
    if (!Platform.isAndroid && _textureId != null) {
      // Use direct FFI path if engine handle is available
      if (_engineHandle != null) {
        ffi.wgpu_mark_frame_available(_engineHandle!, _textureId!);
      } else {
        // Fallback to MethodChannel
        await _channel.invokeMethod<void>('markFrameAvailable', {
          'textureId': _textureId,
        });
      }
    }
  }

  /// Fire-and-forget version of [markFrameAvailable].
  ///
  /// Uses direct FFI on Apple platforms for ~100x lower latency.
  void markFrameAvailableSync() {
    if (_disposed) return;
    if (!Platform.isAndroid && _textureId != null) {
      // Use direct FFI path if engine handle is available
      if (_engineHandle != null) {
        ffi.wgpu_mark_frame_available(_engineHandle!, _textureId!);
      } else {
        // Fallback to MethodChannel
        _channel.invokeMethod<void>('markFrameAvailable', {
          'textureId': _textureId,
        });
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(null);
      _surface?.dispose();
      _surface = null;

      if (_textureId != null) {
        _channel.invokeMethod<void>('destroySurface', {
          'textureId': _textureId,
        });
        _textureId = null;
      }
    } else {
      if (_textureId != null) {
        _channel.invokeMethod<void>('unregisterTexture', {
          'textureId': _textureId,
        });
        _textureId = null;
      }
      _surface?.dispose();
      _surface = null;
    }

    _surfaceReady = false;
    super.dispose();
  }
}
