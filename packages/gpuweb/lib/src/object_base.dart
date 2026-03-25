/// Base interface for all GPU objects with a debug label.
///
/// See [WebGPU spec: GPUObjectBase](https://www.w3.org/TR/webgpu/#gpuobjectbase).
abstract interface class GpuObjectBase {
  /// A human-readable label for debugging.
  String get label;

  /// Sets the debug label.
  set label(String value);
}
