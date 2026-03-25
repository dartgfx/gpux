import 'package:gpuweb/gpuweb.dart';

import 'capabilities.dart';
import 'workarounds.dart';

/// Cross-platform GPU instance (unsupported platform stub).
class Gpu implements GpuInstance {
  Gpu() {
    throw UnsupportedError('GPU is not supported on this platform.');
  }

  @override
  GpuTextureFormat get preferredCanvasFormat => throw UnimplementedError();

  @override
  Set<GpuWgslLanguageFeatureName> get wgslLanguageFeatures =>
      throw UnimplementedError();

  @override
  Future<GpuAdapter> requestAdapter([
    GpuRequestAdapterOptions options = const GpuRequestAdapterOptions(),
  ]) => throw UnimplementedError();
}

/// Queries downlevel capability flags from the [adapter].
///
/// Throws on unsupported platforms.
GpuDownlevel queryDownlevel(GpuAdapter adapter) => throw UnsupportedError(
  'GPU is not supported on this platform.',
);

/// Queries active workarounds for the [adapter].
///
/// Throws on unsupported platforms.
GpuWorkarounds queryWorkarounds(GpuAdapter adapter) => throw UnsupportedError(
  'GPU is not supported on this platform.',
);
