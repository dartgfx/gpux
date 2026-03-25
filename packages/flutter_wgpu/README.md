# flutter_wgpu

Flutter plugin that displays wgpu GPU surfaces as Flutter textures. Handles the platform-specific texture sharing so you can render with wgpu and show it in a Flutter widget.

## Platform support

| Platform | Method |
|----------|--------|
| macOS, iOS | IOSurface (zero-copy) |
| Android | SurfaceProducer |
| Windows, Linux | Pixel buffer copy |

## Usage

```dart
final controller = WgpuTextureController(
  deviceHandle: device.handle,
  width: 800,
  height: 600,
);
await controller.initialize();

// Render to controller.surface
// ...

// Display in widget tree
WgpuTextureWidget(controller: controller)
```

Most users should use `flutter_gpux` instead, which wraps this with a higher-level `GpuRenderer` API.
