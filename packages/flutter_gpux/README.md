# flutter_gpux

Flutter widget for GPU rendering. Wrap your GPU code in a `GpuRenderer`, drop it in a `GpuView`, done.

## Usage

```dart
DefaultGpu(
  child: GpuView(renderer: MyRenderer()),
)
```

`GpuRenderer` is where your GPU code lives:

```dart
class MyRenderer extends GpuRenderer {
  MyRenderer({required super.repaint});

  GpuRenderPipeline? _pipeline;

  @override
  bool render(GpuFrame frame) {
    _pipeline ??= _createPipeline(frame.device, frame.format);

    final enc = frame.device.createCommandEncoder();
    final pass = enc.beginRenderPass(colorAttachments: [
      GpuColorAttachment(
        view: frame.targetView,
        loadOp: GpuLoadOp.clear,
        storeOp: GpuStoreOp.store,
        clearValue: const GpuColor(0, 0, 0, 1),
      ),
    ]);
    pass.setPipeline(_pipeline!);
    pass.draw(vertexCount: 3);
    pass.end();
    frame.device.queue.submit([enc.finish()]);
    return true;
  }

  @override
  bool shouldUpdate(covariant MyRenderer old) => false;
}
```

Multiple views can share the same device:

```dart
DefaultGpu(
  child: Column(children: [
    GpuView(renderer: sceneRenderer),
    GpuView(renderer: minimapRenderer),
  ]),
)
```

## Platform notes

macOS/iOS share GPU textures with Flutter via IOSurface (zero-copy). Android renders straight to the swapchain.

Windows and Linux don't have a way to share GPU textures with Flutter's compositor yet, so each frame gets copied through CPU memory. Adds about 1-3ms at 1080p.

## Example

The `example/` app loads a glTF model with PBR shading:

```
cd example
flutter run -d macos
```
