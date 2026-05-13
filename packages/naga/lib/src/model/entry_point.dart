/// Shader entry point.
final class NagaEntryPoint {
  /// Creates a shader entry point.
  const NagaEntryPoint(this.stage, this.name);

  /// Creates a vertex shader entry point.
  const NagaEntryPoint.vertex(String name) : this(NagaShaderStage.vertex, name);

  /// Creates a fragment shader entry point.
  const NagaEntryPoint.fragment(String name)
    : this(NagaShaderStage.fragment, name);

  /// Creates a compute shader entry point.
  const NagaEntryPoint.compute(String name)
    : this(NagaShaderStage.compute, name);

  /// The shader stage.
  final NagaShaderStage stage;

  /// The entry point name.
  final String name;
}

/// Shader stage.
enum NagaShaderStage {
  /// Vertex shader stage.
  vertex,

  /// Fragment shader stage.
  fragment,

  /// Compute shader stage.
  compute,
}
