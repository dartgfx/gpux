import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:gpuweb/gpuweb.dart';
import '../wgpu_ffi.dart' show wgpuLastError, textureFormatFromFfi;
import 'ffi/bindings_generated.dart' as ffi;
import 'resource.dart';
import 'adapter.dart';

/// GPU backend selection for [WgpuInstanceDescriptor].
///
/// Bitmask values matching wgpu 28's `Backends` flags.
/// Note: wgpu 28 added Noop at bit 0, shifting all backends by one.
abstract final class WgpuBackend {
  static const int noop = 1 << 0;
  static const int vulkan = 1 << 1;
  static const int metal = 1 << 2;
  static const int dx12 = 1 << 3;
  static const int gl = 1 << 4;
  static const int browserWebGpu = 1 << 5;

  /// All backends (default).
  static const int all = vulkan | gl | metal | dx12 | browserWebGpu;

  /// Primary backends only (Vulkan, Metal, DX12, BrowserWebGPU).
  static const int primary = vulkan | metal | dx12 | browserWebGpu;
}

/// Configuration for creating a wgpu instance.
///
/// This is wgpu-specific (not part of the WebGPU spec).
/// Controls validation behavior and backend selection.
class WgpuInstanceDescriptor {
  const WgpuInstanceDescriptor({
    this.validation = false,
    this.gpuBasedValidation = false,
    this.backends = 0,
  });

  /// Enable wgpu validation layer (catches API misuse).
  final bool validation;

  /// Enable GPU-based validation (more thorough, higher overhead).
  final bool gpuBasedValidation;

  /// Backend bitmask (see [WgpuBackend]). 0 = all backends.
  final int backends;

  /// Debug configuration with full validation enabled.
  static const debug = WgpuInstanceDescriptor(
    validation: true,
    gpuBasedValidation: true,
  );

  /// Release configuration with no validation.
  static const release = WgpuInstanceDescriptor();
}

/// A wgpu instance — entry point for GPU access.
///
/// Create instances to enumerate adapters and request devices:
/// ```dart
/// final instance = Wgpu.create();
/// final adapter = instance.requestAdapter();
/// final device = adapter.requestDevice();
/// ```
class Wgpu implements GpuInstance, WgpuResource {
  final int _handle;
  bool _disposed = false;

  Wgpu._(this._handle);

  /// The native handle for this instance.
  int get handle => _handle;

  @override
  bool get isDisposed => _disposed;

  /// Create a new wgpu instance.
  ///
  /// [descriptor] controls wgpu-specific validation behavior.
  static Wgpu create([
    WgpuInstanceDescriptor descriptor = const WgpuInstanceDescriptor(),
  ]) {
    return using((arena) {
      final desc = arena<ffi.WGPUInstanceDescriptor>();
      desc.ref.validation = descriptor.validation ? 1 : 0;
      desc.ref.gpu_based_validation = descriptor.gpuBasedValidation ? 1 : 0;
      desc.ref.backends = descriptor.backends;

      final handle = ffi.wgpun_CreateInstance(desc);

      if (handle == 0) {
        throw StateError('Failed to create GPU instance: ${wgpuLastError()}');
      }

      return Wgpu._(handle);
    });
  }

  @override
  GpuTextureFormat get preferredCanvasFormat =>
      textureFormatFromFfi(ffi.wgpu_get_surface_format(0));

  @override
  Set<GpuWgslLanguageFeatureName> get wgslLanguageFeatures {
    final bits = ffi.wgpun_InstanceGetWGSLLanguageFeatures(_handle);
    final result = <GpuWgslLanguageFeatureName>{};
    for (final feature in GpuWgslLanguageFeatureName.values) {
      if (bits & (1 << feature.index) != 0) {
        result.add(feature);
      }
    }
    return result;
  }

  @override
  Future<WgpuAdapter> requestAdapter([
    GpuRequestAdapterOptions options = const GpuRequestAdapterOptions(),
  ]) async {
    return using((arena) {
      final opts = arena<ffi.WGPURequestAdapterOptions>();
      opts.ref.power_preference = options.powerPreference?.index ?? 0;
      opts.ref.force_fallback_adapter = options.forceFallbackAdapter ? 1 : 0;

      final handle = ffi.wgpun_InstanceRequestAdapter(_handle, opts);

      if (handle == 0) {
        throw StateError('Failed to request adapter: ${wgpuLastError()}');
      }

      return WgpuAdapter.internal(handle, this);
    });
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ffi.wgpun_InstanceRelease(_handle);
  }
}
