import 'dart:typed_data';

import 'object_base.dart';

/// Buffer map state.
///
/// See [WebGPU spec: GPUBufferMapState](https://www.w3.org/TR/webgpu/#enumdef-gpubuffermapstate).
enum GpuBufferMapState {
  /// The buffer is not mapped.
  unmapped,

  /// A map operation is pending.
  pending,

  /// The buffer is mapped and accessible from the CPU.
  mapped,
}

/// A GPU buffer.
///
/// See [WebGPU spec: GPUBuffer](https://www.w3.org/TR/webgpu/#gpubuffer).
abstract interface class GpuBuffer implements GpuObjectBase {
  /// Size in bytes.
  int get size;

  /// Buffer usage flags.
  GpuBufferUsageFlags get usage;

  /// Current map state.
  GpuBufferMapState get mapState;

  /// Maps the buffer asynchronously.
  Future<void> mapAsync(GpuMapModeFlags mode, {int offset, int? size});

  /// Returns a view of the mapped range.
  ///
  /// Can only be called when [mapState] is [GpuBufferMapState.mapped].
  ByteBuffer getMappedRange({int offset, int? size});

  /// Unmaps the buffer, making it available for GPU use again.
  void unmap();

  /// Destroys the buffer, releasing GPU memory.
  void destroy();
}

/// Buffer usage flags.
///
/// Combine with `|` operator.
/// See [WebGPU spec: GPUBufferUsage](https://www.w3.org/TR/webgpu/#typedefdef-gpubufferusageflags).
extension type const GpuBufferUsageFlags(int _) implements int {
  /// Combines this flag with another usage flag.
  GpuBufferUsageFlags operator |(int other) => GpuBufferUsageFlags(_ | other);
}

/// Buffer usage flag constants.
///
/// See [WebGPU spec: GPUBufferUsage](https://www.w3.org/TR/webgpu/#typedefdef-gpubufferusageflags).
abstract class GpuBufferUsage {
  /// Buffer can be mapped for reading.
  static const mapRead = GpuBufferUsageFlags(0x0001);

  /// Buffer can be mapped for writing.
  static const mapWrite = GpuBufferUsageFlags(0x0002);

  /// Buffer can be used as a copy source.
  static const copySrc = GpuBufferUsageFlags(0x0004);

  /// Buffer can be used as a copy destination.
  static const copyDst = GpuBufferUsageFlags(0x0008);

  /// Buffer can be used as an index buffer.
  static const index = GpuBufferUsageFlags(0x0010);

  /// Buffer can be used as a vertex buffer.
  static const vertex = GpuBufferUsageFlags(0x0020);

  /// Buffer can be used as a uniform buffer.
  static const uniform = GpuBufferUsageFlags(0x0040);

  /// Buffer can be used as a storage buffer.
  static const storage = GpuBufferUsageFlags(0x0080);

  /// Buffer can be used for indirect draw/dispatch arguments.
  static const indirect = GpuBufferUsageFlags(0x0100);

  /// Buffer can be used as the destination for query resolve.
  static const queryResolve = GpuBufferUsageFlags(0x0200);
}

/// Map mode flags.
///
/// See [WebGPU spec: GPUMapMode](https://www.w3.org/TR/webgpu/#typedefdef-gpumapmodeflags).
extension type const GpuMapModeFlags(int _) implements int {
  /// Combines this flag with another map mode flag.
  GpuMapModeFlags operator |(int other) => GpuMapModeFlags(_ | other);
}

/// Map mode flag constants.
///
/// See [WebGPU spec: GPUMapMode](https://www.w3.org/TR/webgpu/#typedefdef-gpumapmodeflags).
abstract class GpuMapMode {
  /// Map for reading.
  static const read = GpuMapModeFlags(0x0001);

  /// Map for writing.
  static const write = GpuMapModeFlags(0x0002);
}
