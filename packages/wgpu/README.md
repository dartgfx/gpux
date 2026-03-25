# wgpu

Dart FFI bindings for [wgpu](https://wgpu.rs). Metal, Vulkan, DX12.

## Platforms

| Platform     | Backend |
|-------------|---------|
| macOS, iOS  | Metal   |
| Windows     | DX12    |
| Linux, Android | Vulkan |

## Usage

```dart
import 'package:wgpu/wgpu.dart';

final instance = Wgpu.create();
final adapter = await instance.requestAdapter();
final device = await adapter.requestDevice();

// Create a buffer
final buffer = device.createBuffer(
  size: 256,
  usage: GpuBufferUsage.vertex | GpuBufferUsage.copyDst,
);

// Render pass
final encoder = device.createCommandEncoder();
final pass = encoder.beginRenderPass(
  colorAttachments: [
    GpuColorAttachment(
      view: texture.createView(),
      loadOp: GpuLoadOp.clear,
      storeOp: GpuStoreOp.store,
    ),
  ],
);
pass.setPipeline(pipeline);
pass.draw(vertexCount: 3);
pass.end();

device.queue.submit([encoder.finish()]);
```

## Compute

```dart
final shader = device.createShaderModule(wgslSource);
final pipeline = device.createComputePipeline(module: shader, layout: null);

final encoder = device.createCommandEncoder();
final pass = encoder.beginComputePass();
pass.setPipeline(pipeline);
pass.setBindGroup(0, bindGroup);
pass.dispatchWorkgroups(64);
pass.end();

device.queue.submit([encoder.finish()]);
```

## Regenerating bindings

When FFI functions change in `native/src/lib.rs`:

```bash
./gen_bindings.sh
```

Requires `cbindgen` (`cargo install cbindgen`).
