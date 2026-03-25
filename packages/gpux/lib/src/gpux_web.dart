import 'package:gpuweb_js/gpuweb_js.dart';

import 'capabilities.dart';
import 'workarounds.dart';

/// Cross-platform GPU instance (web implementation).
///
/// Delegates to [WebGpu] via browser WebGPU (dart:js_interop).
class Gpu implements GpuInstance {
  /// Creates a GPU instance.
  Gpu() : _instance = WebGpu();

  final WebGpu _instance;

  @override
  GpuTextureFormat get preferredCanvasFormat => _instance.preferredCanvasFormat;

  @override
  Set<GpuWgslLanguageFeatureName> get wgslLanguageFeatures =>
      _instance.wgslLanguageFeatures;

  @override
  Future<GpuAdapter> requestAdapter([
    GpuRequestAdapterOptions options = const GpuRequestAdapterOptions(),
  ]) => _instance.requestAdapter(options);
}

/// Queries downlevel capability flags from the [adapter].
///
/// On web, all capabilities are guaranteed by the WebGPU spec baseline.
GpuDownlevel queryDownlevel(GpuAdapter adapter) =>
    GpuDownlevel(GpuCapability.values.toSet());

/// Queries active workarounds for the [adapter].
///
/// On web, no workarounds are needed — the browser handles driver quirks.
GpuWorkarounds queryWorkarounds(GpuAdapter adapter) => GpuWorkarounds.none;
