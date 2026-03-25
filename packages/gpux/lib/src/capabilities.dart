/// GPU capabilities that may not be available on all adapters.
///
/// These correspond to wgpu's `DownlevelFlags` — capabilities that are
/// guaranteed on WebGPU-compliant adapters but may be absent on downlevel
/// backends (e.g. GLES 3.0).
enum GpuCapability {
  /// Compute shader support.
  computeShaders,

  /// Indirect draw/dispatch execution.
  indirectExecution,

  /// Storage buffers/textures visible to vertex shaders.
  vertexStorage,

  /// Storage buffers/textures visible to fragment shaders.
  fragmentStorage,

  /// Anisotropic texture filtering.
  anisotropicFiltering,

  /// Per-target blend states (different writeMask/blend per color target).
  independentBlend,
}

/// Downlevel capability flags for a GPU adapter.
///
/// On WebGPU-compliant adapters (web), all capabilities are present.
/// On native (wgpu), some GLES backends lack certain capabilities.
///
/// ```dart
/// // Via GpuController (typical usage):
/// if (controller.downlevel.supports(GpuCapability.computeShaders)) {
///   // Safe to use compute pipelines.
/// }
/// ```
class GpuDownlevel {
  /// Creates a [GpuDownlevel] from a set of supported capabilities.
  const GpuDownlevel(this._flags);

  final Set<GpuCapability> _flags;

  /// Whether the adapter supports the given [capability].
  bool supports(GpuCapability capability) => _flags.contains(capability);

  @override
  String toString() => 'GpuDownlevel(${_flags.join(', ')})';
}
