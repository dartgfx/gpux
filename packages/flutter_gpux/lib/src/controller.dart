import 'package:gpux/gpux.dart';
import 'package:gpux/internal.dart';

/// Shared GPU device for [GpuView] widgets.
///
/// [GpuView] creates one automatically via [DefaultGpu] — use this
/// explicitly when sharing a device across multiple views.
///
/// For non-widget GPU usage (compute, offscreen), use [Gpu] directly.
///
/// All getters except [isInitialized] require [initialize] to have completed.
///
/// ```dart
/// final controller = GpuController();
/// await controller.initialize();
/// GpuView(controller: controller, renderer: rendererA);
/// GpuView(controller: controller, renderer: rendererB);
/// ```
class GpuController {
  /// [instance] optionally provides a custom GPU instance (e.g.,
  /// `Wgpu.create(WgpuInstanceDescriptor.debug)` for validation).
  /// Defaults to [Gpu] (cross-platform).
  GpuController({
    GpuInstance? instance,
  }) : _instance = instance;

  final GpuInstance? _instance;
  GpuInstance? _gpuInstance;
  GpuDevice? _device;
  GpuDownlevel _downlevel = GpuDownlevel(GpuCapability.values.toSet());
  GpuWorkarounds _workarounds = GpuWorkarounds.none;
  bool _initialized = false;
  bool _disposed = false;
  GpuAdapterInfo? _adapterInfo;

  /// The GPU device for creating resources and submitting commands.
  GpuDevice get device {
    if (!_initialized) {
      throw StateError('GpuController not initialized. Call initialize().');
    }
    return _device!;
  }

  /// Preferred surface texture format. On native, the actual format is
  /// negotiated per-surface — use [GpuFrame.format] in renderers.
  GpuTextureFormat get format {
    if (!_initialized) {
      throw StateError('GpuController not initialized. Call initialize().');
    }
    return _gpuInstance!.preferredCanvasFormat;
  }

  /// Downlevel capability flags for the adapter.
  GpuDownlevel get downlevel => _downlevel;

  /// Whether indirect draw/dispatch is supported.
  bool get supportsIndirect =>
      _downlevel.supports(GpuCapability.indirectExecution);

  /// Whether compute shaders are supported.
  bool get supportsCompute => _downlevel.supports(GpuCapability.computeShaders);

  /// Whether storage buffers are visible to vertex shaders.
  bool get supportsVertexStorage =>
      _downlevel.supports(GpuCapability.vertexStorage);

  /// Active workarounds for known driver bugs.
  GpuWorkarounds get workarounds => _workarounds;

  /// Information about the GPU adapter (vendor, device name, backend).
  GpuAdapterInfo get adapterInfo {
    if (!_initialized) {
      throw StateError('GpuController not initialized. Call initialize().');
    }
    return _adapterInfo!;
  }

  /// Whether [initialize] has completed successfully.
  bool get isInitialized => _initialized;

  /// Initializes the GPU — creates adapter and device.
  Future<void> initialize({
    Set<GpuFeatureName> features = const {},
  }) async {
    if (_disposed) throw StateError('GpuController already disposed.');
    if (_initialized) return;

    final instance = _instance ?? Gpu();
    _gpuInstance = instance;
    final adapter = await instance.requestAdapter();
    _downlevel = queryDownlevel(adapter);
    _workarounds = queryWorkarounds(adapter);
    final unsupported = features.difference(adapter.features);
    if (unsupported.isNotEmpty) {
      throw UnsupportedError(
        'GPU features not available: $unsupported. '
        'Supported: ${adapter.features}',
      );
    }
    final device = await adapter.requestDevice(
      GpuDeviceDescriptor(
        requiredFeatures: features,
        requiredLimits: adapter.limits,
      ),
    );
    _device = device;
    _adapterInfo = adapter.info;
    _initialized = true;
  }

  /// Releases the GPU device.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _device?.destroy();
    _device = null;
  }
}
