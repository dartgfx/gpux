import 'dart:js_interop';

import 'package:gpuweb/gpuweb.dart';
import 'package:meta/meta.dart';

import 'convert.dart';
import 'js/webgpu.dart';
import 'device.dart';
import 'resources.dart';

/// Alpha compositing mode for the canvas.
///
/// See [WebGPU spec: GPUCanvasAlphaMode](https://www.w3.org/TR/webgpu/#enumdef-gpucanvasalphamode).
enum GpuCanvasAlphaMode {
  /// Canvas is fully opaque — alpha channel is ignored.
  opaque,

  /// Canvas uses premultiplied alpha for compositing.
  premultiplied,
}

/// Web implementation of `GPUCanvasContext`.
///
/// Wraps the browser canvas context to configure swap-chain presentation.
///
/// ```dart
/// final context = WebGpuCanvasContext.fromCanvas(canvasElement);
/// context.configure(device: device, format: gpu.preferredCanvasFormat);
///
/// // Each frame:
/// final texture = context.getCurrentTexture();
/// // render to texture.createView() ...
/// device.queue.submit([commands]);
/// ```
class WebGpuCanvasContext {
  WebGpuCanvasContext(this._js);

  /// Gets a WebGPU context from an HTML canvas element.
  ///
  /// [canvas] must be a `<canvas>` DOM element (as a JSObject).
  factory WebGpuCanvasContext.fromCanvas(JSObject canvas) {
    final ctx = _JsCanvas(canvas).getContext('webgpu');
    if (ctx == null) {
      throw StateError(
        'Failed to get WebGPU context from canvas. '
        'Ensure WebGPU is supported and the element is a <canvas>.',
      );
    }
    return WebGpuCanvasContext(JsGpuCanvasContext(ctx));
  }

  final JsGpuCanvasContext _js;

  @internal
  JsGpuCanvasContext get jsContext => _js;

  /// Configures the canvas context for presentation.
  void configure({
    required WebGpuDevice device,
    required GpuTextureFormat format,
    GpuTextureUsageFlags usage = const GpuTextureUsageFlags(
      0x10,
    ), // renderAttachment
    GpuCanvasAlphaMode alphaMode = GpuCanvasAlphaMode.opaque,
    List<GpuTextureFormat> viewFormats = const [],
  }) {
    final desc =
        <String, Object?>{
              'device': device.jsDevice,
              'format': textureFormatToJs(format),
              'usage': usage as int,
              'alphaMode': alphaMode.name,
              if (viewFormats.isNotEmpty)
                'viewFormats': [
                  for (final f in viewFormats) textureFormatToJs(f),
                ],
            }.jsify()
            as JSObject;
    _js.configure(desc);
  }

  /// Removes the canvas configuration.
  void unconfigure() => _js.unconfigure();

  /// Returns the current texture for this frame.
  ///
  /// Call this once per frame, render into it, then submit commands.
  /// The browser presents the texture automatically after the current
  /// task completes.
  WebGpuTexture getCurrentTexture() => WebGpuTexture(_js.getCurrentTexture());
}

extension type _JsCanvas(JSObject _) implements JSObject {
  external JSObject? getContext(String contextId);
}
