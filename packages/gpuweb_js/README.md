# gpuweb_js

WebGPU bindings for Dart on the web. Talks to the browser's `navigator.gpu` through `dart:js_interop`.

Requires a browser with WebGPU support (Chrome 113+, Edge 113+, Firefox behind flag).

## Usage

```dart
import 'package:gpuweb_js/gpuweb_js.dart';

final instance = WebGpu();
final adapter = await instance.requestAdapter();
final device = await adapter.requestDevice();
```

Most users should use `gpux` instead, which picks the right backend automatically. Use this package directly if you're building something web-only.

## Canvas rendering

```dart
final context = WebGpuCanvasContext.fromCanvas(canvasElement);
context.configure(device: device, format: instance.preferredCanvasFormat);

// each frame
final texture = context.getCurrentTexture();
// render into texture.createView() ...
device.queue.submit([commands]);
```
