# gpux

Cross-platform GPU for Dart. Uses WebGPU in the browser, wgpu everywhere else. The API follows the WebGPU spec so there's nothing new to learn if you've used it before.

```dart
import 'package:gpux/gpux.dart';

final gpu = Gpu();
final adapter = await gpu.requestAdapter();
final device = await adapter.requestDevice();
```

## Downlevel capabilities

Not every adapter supports the full spec (especially GLES fallbacks on old Android). Check before using optional features:

```dart
final downlevel = queryDownlevel(adapter);
if (downlevel.supports(GpuCapability.computeShaders)) {
  // safe to create compute pipelines
}

final workarounds = queryWorkarounds(adapter);
if (!workarounds.brokenMipmapGeneration) {
  generateMipmaps(texture);
}
```

## Blocklist

On Android, some Vulkan drivers are broken beyond repair (old Adreno, Huawei Maleoon, pre-BXE PowerVR). gpux detects these at startup and falls back to GLES automatically.

## Flutter

For rendering to a Flutter widget, see `flutter_gpux`.
