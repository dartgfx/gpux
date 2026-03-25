import 'dart:typed_data';

import 'buffer.dart';
import 'encoder.dart';
import 'object_base.dart';
import 'texture.dart';

/// Command queue for submitting GPU work.
///
/// See [WebGPU spec: GPUQueue](https://www.w3.org/TR/webgpu/#gpuqueue).
abstract interface class GpuQueue implements GpuObjectBase {
  /// Submits command buffers for execution.
  void submit(List<GpuCommandBuffer> commandBuffers);

  /// Returns a Future that resolves when all previously submitted work is done.
  Future<void> onSubmittedWorkDone();

  /// Writes data to a buffer.
  void writeBuffer(
    GpuBuffer buffer,
    Uint8List data, {
    int bufferOffset = 0,
    int dataOffset = 0,
    int? size,
  });

  /// Writes data to a texture.
  void writeTexture({
    required GpuTexture texture,
    required Uint8List data,
    required int bytesPerRow,
    required int width,
    int height = 1,
    int depthOrArrayLayers = 1,
    int mipLevel = 0,
    GpuTextureAspect aspect = GpuTextureAspect.all,
    int originX = 0,
    int originY = 0,
    int originZ = 0,
    int dataOffset = 0,
    int? rowsPerImage,
  });
}
