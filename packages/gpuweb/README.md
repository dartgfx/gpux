# gpuweb

Pure Dart interfaces for the [WebGPU](https://www.w3.org/TR/webgpu/) API.

Abstract interfaces, enums, descriptors, and flag types — no implementation.
Depend on a backend (e.g. `wgpu`) for a concrete implementation.

```dart
import 'package:gpuweb/gpuweb.dart';

void render(GpuDevice device) {
  final encoder = device.createCommandEncoder();
  final pass = encoder.beginRenderPass(
    colorAttachments: [
      GpuColorAttachment(
        view: textureView,
        loadOp: GpuLoadOp.clear,
        storeOp: GpuStoreOp.store,
      ),
    ],
  );
  pass.setPipeline(pipeline);
  pass.draw(vertexCount: 3);
  pass.end();
  device.queue.submit([encoder.finish()]);
}
```

## Interfaces

```
GpuInstance / GpuAdapter / GpuDevice   Resource creation, feature/limit queries
GpuQueue                               Command submission, buffer/texture writes
GpuBuffer / GpuTexture / GpuSampler    GPU resources
GpuShaderModule                        Compiled WGSL
GpuBindGroup / GpuPipelineLayout       Resource binding
GpuRenderPipeline / GpuComputePipeline Pipeline state
GpuCommandEncoder / GpuCommandBuffer   Command recording and submission
GpuRenderPassEncoder                   Draw calls
GpuComputePassEncoder                  Compute dispatches
GpuRenderBundle / GpuQuerySet          Pre-recorded commands, GPU queries
```

## Backends

| Package | Backend | Platform |
|---------|---------|----------|
| `wgpu` | [wgpu](https://wgpu.rs/) via FFI | macOS, Windows, Linux, Android |
| `gpuweb_js` | [WebGPU](https://www.w3.org/TR/webgpu/) via `dart:js_interop` | Web |
