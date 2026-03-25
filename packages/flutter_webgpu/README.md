# flutter_webgpu

Flutter widget for WebGPU rendering on the web. Manages an HTML canvas element and its WebGPU context within Flutter's platform view system.

## Usage

```dart
GpuWebView(
  device: device,
  format: gpu.preferredCanvasFormat,
  onCreated: (ctx, w, h) {
    // create pipelines, buffers, etc.
  },
  onRender: (ctx, w, h) {
    final texture = ctx.getCurrentTexture();
    // render into texture.createView() ...
    device.queue.submit([commands]);
  },
)
```

Most users should use `flutter_gpux` instead, which wraps this with a higher-level `GpuRenderer` API.
