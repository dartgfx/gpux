import 'object_base.dart';

/// Query set types.
///
/// See [WebGPU spec: GPUQueryType](https://www.w3.org/TR/webgpu/#enumdef-gpuquerytype).
enum GpuQueryType {
  /// Timestamp queries (GPU clock values).
  timestamp,

  /// Occlusion queries (number of samples that pass depth/stencil).
  occlusion,
}

/// A set of GPU queries.
///
/// See [WebGPU spec: GPUQuerySet](https://www.w3.org/TR/webgpu/#gpuqueryset).
abstract interface class GpuQuerySet implements GpuObjectBase {
  /// The type of queries in this set.
  GpuQueryType get type;

  /// The number of queries in this set.
  int get count;

  /// Destroys the query set.
  void destroy();
}
