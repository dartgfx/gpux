/// WGSL target options.
final class NagaWgslOptions {
  /// Creates WGSL target options.
  const NagaWgslOptions({
    this.explicitTypes = false,
  });

  /// Always emit explicit type annotations instead of relying on inference.
  final bool explicitTypes;
}

/// SPIR-V target options.
final class NagaSpirvOptions {
  /// Creates SPIR-V target options.
  const NagaSpirvOptions({
    this.debugNames = false,
    this.adjustCoordinateSpace = true,
    this.labelVaryings = true,
    this.forcePointSize = false,
    this.clampFragDepth = true,
  });

  /// Emit debug names.
  final bool debugNames;

  /// Flip Y coordinate of position output.
  final bool adjustCoordinateSpace;

  /// Emit names for input/output locations.
  final bool labelVaryings;

  /// Emit point size output for vertex shaders.
  final bool forcePointSize;

  /// Clamp fragment depth output between 0 and 1.
  final bool clampFragDepth;
}

/// MSL target options.
final class NagaMslOptions {
  /// Creates MSL target options.
  const NagaMslOptions({
    this.spirvCrossCompatibility = false,
    this.fakeMissingBindings = true,
    this.zeroInitializeWorkgroupMemory = true,
    this.forceLoopBounding = true,
  });

  /// Make output more compatible with SPIRV-Cross stage linking.
  final bool spirvCrossCompatibility;

  /// Generate placeholder bindings instead of failing on missing binding maps.
  final bool fakeMissingBindings;

  /// Zero-initialize workgroup memory by polyfilling where needed.
  final bool zeroInitializeWorkgroupMemory;

  /// Inject loop bounds to help compilers reason about loops.
  final bool forceLoopBounding;
}

/// HLSL target options.
final class NagaHlslOptions {
  /// Creates HLSL target options.
  const NagaHlslOptions({
    this.shaderModel = NagaHlslShaderModel.v5_1,
    this.fakeMissingBindings = true,
    this.zeroInitializeWorkgroupMemory = true,
    this.restrictIndexing = true,
    this.forceLoopBounding = true,
    this.rayQueryInitializationTracking = true,
  });

  /// HLSL shader model to emit.
  final NagaHlslShaderModel shaderModel;

  /// Generate placeholder bindings instead of failing on missing binding maps.
  final bool fakeMissingBindings;

  /// Zero-initialize workgroup memory by polyfilling where needed.
  final bool zeroInitializeWorkgroupMemory;

  /// Restrict vector, matrix, and array indexing.
  final bool restrictIndexing;

  /// Inject loop bounds to help compilers reason about loops.
  final bool forceLoopBounding;

  /// Track ray query initialization to prevent misuse.
  final bool rayQueryInitializationTracking;
}

/// HLSL shader model.
enum NagaHlslShaderModel {
  /// Shader model 5.0.
  v5_0,

  /// Shader model 5.1.
  v5_1,

  /// Shader model 6.0.
  v6_0,

  /// Shader model 6.1.
  v6_1,

  /// Shader model 6.2.
  v6_2,

  /// Shader model 6.3.
  v6_3,

  /// Shader model 6.4.
  v6_4,

  /// Shader model 6.5.
  v6_5,

  /// Shader model 6.6.
  v6_6,

  /// Shader model 6.7.
  v6_7,

  /// Shader model 6.8.
  v6_8,

  /// Shader model 6.9.
  v6_9,
}

/// GLSL target options.
final class NagaGlslOptions {
  /// Creates GLSL target options.
  const NagaGlslOptions({
    this.adjustCoordinateSpace = true,
    this.textureShadowLod = false,
    this.drawParameters = false,
    this.includeUnusedItems = false,
    this.forcePointSize = false,
    this.zeroInitializeWorkgroupMemory = true,
  });

  /// Flip output Y and expand Z from 0..1 to -1..1.
  final bool adjustCoordinateSpace;

  /// Allow GL_EXT_texture_shadow_lod.
  final bool textureShadowLod;

  /// Allow ARB_shader_draw_parameters.
  final bool drawParameters;

  /// Include unused globals, constants, and functions.
  final bool includeUnusedItems;

  /// Emit point size output for vertex shaders.
  final bool forcePointSize;

  /// Zero-initialize workgroup memory by polyfilling where needed.
  final bool zeroInitializeWorkgroupMemory;
}
