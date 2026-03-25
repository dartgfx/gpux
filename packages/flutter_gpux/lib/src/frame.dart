import 'package:gpux/gpux.dart';

/// Per-frame GPU rendering context passed to [GpuRenderer.render].
///
/// Provides everything needed to encode and submit GPU commands
/// ```dart
/// final texture = device.createTexture(...);
/// final frame = GpuFrame(
///   device: device,
///   format: GpuTextureFormat.rgba8unorm,
///   targetView: texture.createView(),
///   width: 1024,
///   height: 1024,
/// );
/// renderer.render(frame);
/// ```
class GpuFrame {
  GpuFrame({
    required this.device,
    required this.format,
    required this.targetView,
    required this.width,
    required this.height,
  });

  /// The GPU device for creating resources and submitting commands.
  GpuDevice device;

  /// The surface texture format (needed for pipeline color targets).
  GpuTextureFormat format;

  /// The texture view to render into as a color attachment.
  GpuTextureView targetView;

  /// Surface width in pixels.
  int width;

  /// Surface height in pixels.
  int height;
}
