import 'device.dart';

/// GPU feature names.
///
/// See [WebGPU spec: GPUFeatureName](https://www.w3.org/TR/webgpu/#enumdef-gpufeaturename).
enum GpuFeatureName {
  /// Baseline features and limits for all devices.
  coreFeaturesAndLimits,

  /// Allows `unclippedDepth` in primitive state.
  depthClipControl,

  /// Enables the `depth32float-stencil8` texture format.
  depth32FloatStencil8,

  /// Enables BC compressed texture formats.
  textureCompressionBc,

  /// Enables BC compressed textures with 3D slicing.
  textureCompressionBcSliced3d,

  /// Enables ETC2 compressed texture formats.
  textureCompressionEtc2,

  /// Enables ASTC compressed texture formats.
  textureCompressionAstc,

  /// Enables ASTC compressed textures with 3D slicing.
  textureCompressionAstcSliced3d,

  /// Enables timestamp queries on compute and render passes.
  timestampQuery,

  /// Allows non-zero `firstInstance` in indirect draw calls.
  indirectFirstInstance,

  /// Enables `f16` type in WGSL shaders.
  shaderF16,

  /// Allows RG11B10UFloat format as a render target.
  rg11b10UfloatRenderable,

  /// Allows BGRA8Unorm format as a storage texture.
  bgra8UnormStorage,

  /// Allows float32 texture formats to be filtered.
  float32Filterable,

  /// Allows float32 texture formats to be blended.
  float32Blendable,

  /// Enables `clip_distances` builtin in WGSL.
  clipDistances,

  /// Enables dual-source blending (src1, oneMinusSrc1, etc.).
  dualSourceBlending,

  /// Enables subgroup operations in shaders.
  subgroups,

  /// Enables tier 1 extended texture formats (16-bit normalized, etc.).
  textureFormatsTier1,

  /// Enables tier 2 extended texture formats (16-bit normalized on more types).
  textureFormatsTier2,

  /// Enables `primitive_index` builtin in WGSL fragment shaders.
  primitiveIndex,

  /// Enables texture component swizzle on texture views.
  textureComponentSwizzle,
}

/// Information about a GPU adapter.
///
/// String fields may be empty if the implementation does not expose them.
/// See [WebGPU spec: GPUAdapterInfo](https://www.w3.org/TR/webgpu/#gpuadapterinfo).
class GpuAdapterInfo {
  /// Creates adapter info with the given properties.
  GpuAdapterInfo({
    this.vendor = '',
    this.architecture = '',
    this.device = '',
    this.description = '',
    this.subgroupMinSize = 0,
    this.subgroupMaxSize = 0,
    this.isFallbackAdapter = false,
  });

  /// Vendor name as a normalized identifier string.
  final String vendor;

  /// Architecture name (e.g., "common-3" for ARM Mali).
  final String architecture;

  /// Device name (e.g., "Apple M1 Pro").
  final String device;

  /// Driver description string.
  final String description;

  /// Minimum subgroup size supported by the adapter.
  final int subgroupMinSize;

  /// Maximum subgroup size supported by the adapter.
  final int subgroupMaxSize;

  /// Whether this is a software/fallback adapter.
  final bool isFallbackAdapter;
}

/// Hardware limits for a GPU adapter or device.
///
/// All values default to 0 (unknown). Actual limits are populated by the
/// implementation when querying the adapter or device.
/// See [WebGPU spec: GPUSupportedLimits](https://www.w3.org/TR/webgpu/#gpusupportedlimits).
class GpuLimits {
  /// Creates limits with the given values.
  GpuLimits({
    this.maxTextureDimension1d = 0,
    this.maxTextureDimension2d = 0,
    this.maxTextureDimension3d = 0,
    this.maxTextureArrayLayers = 0,
    this.maxBindGroups = 0,
    this.maxBindGroupsPlusVertexBuffers = 0,
    this.maxBindingsPerBindGroup = 0,
    this.maxDynamicUniformBuffersPerPipelineLayout = 0,
    this.maxDynamicStorageBuffersPerPipelineLayout = 0,
    this.maxSampledTexturesPerShaderStage = 0,
    this.maxSamplersPerShaderStage = 0,
    this.maxStorageBuffersPerShaderStage = 0,
    this.maxStorageTexturesPerShaderStage = 0,
    this.maxStorageBuffersInVertexStage = 0,
    this.maxStorageBuffersInFragmentStage = 0,
    this.maxStorageTexturesInVertexStage = 0,
    this.maxStorageTexturesInFragmentStage = 0,
    this.maxUniformBuffersPerShaderStage = 0,
    this.maxUniformBufferBindingSize = 0,
    this.maxStorageBufferBindingSize = 0,
    this.minUniformBufferOffsetAlignment = 0,
    this.minStorageBufferOffsetAlignment = 0,
    this.maxVertexBuffers = 0,
    this.maxBufferSize = 0,
    this.maxVertexAttributes = 0,
    this.maxVertexBufferArrayStride = 0,
    this.maxInterStageShaderVariables = 0,
    this.maxColorAttachments = 0,
    this.maxColorAttachmentBytesPerSample = 0,
    this.maxComputeWorkgroupStorageSize = 0,
    this.maxComputeInvocationsPerWorkgroup = 0,
    this.maxComputeWorkgroupSizeX = 0,
    this.maxComputeWorkgroupSizeY = 0,
    this.maxComputeWorkgroupSizeZ = 0,
    this.maxComputeWorkgroupsPerDimension = 0,
  });

  /// Maximum 1D texture width.
  final int maxTextureDimension1d;

  /// Maximum 2D texture width or height.
  final int maxTextureDimension2d;

  /// Maximum 3D texture width, height, or depth.
  final int maxTextureDimension3d;

  /// Maximum number of array layers in a texture.
  final int maxTextureArrayLayers;

  /// Maximum number of bind groups in a pipeline layout.
  final int maxBindGroups;

  /// Maximum bind groups plus vertex buffers combined.
  final int maxBindGroupsPlusVertexBuffers;

  /// Maximum number of bindings in a single bind group.
  final int maxBindingsPerBindGroup;

  /// Maximum dynamic uniform buffers per pipeline layout.
  final int maxDynamicUniformBuffersPerPipelineLayout;

  /// Maximum dynamic storage buffers per pipeline layout.
  final int maxDynamicStorageBuffersPerPipelineLayout;

  /// Maximum sampled textures per shader stage.
  final int maxSampledTexturesPerShaderStage;

  /// Maximum samplers per shader stage.
  final int maxSamplersPerShaderStage;

  /// Maximum storage buffers per shader stage.
  final int maxStorageBuffersPerShaderStage;

  /// Maximum storage textures per shader stage.
  final int maxStorageTexturesPerShaderStage;

  /// Maximum storage buffers in the vertex stage.
  final int maxStorageBuffersInVertexStage;

  /// Maximum storage buffers in the fragment stage.
  final int maxStorageBuffersInFragmentStage;

  /// Maximum storage textures in the vertex stage.
  final int maxStorageTexturesInVertexStage;

  /// Maximum storage textures in the fragment stage.
  final int maxStorageTexturesInFragmentStage;

  /// Maximum uniform buffers per shader stage.
  final int maxUniformBuffersPerShaderStage;

  /// Maximum size in bytes of a uniform buffer binding.
  final int maxUniformBufferBindingSize;

  /// Maximum size in bytes of a storage buffer binding.
  final int maxStorageBufferBindingSize;

  /// Minimum alignment in bytes for uniform buffer offsets.
  final int minUniformBufferOffsetAlignment;

  /// Minimum alignment in bytes for storage buffer offsets.
  final int minStorageBufferOffsetAlignment;

  /// Maximum number of vertex buffers.
  final int maxVertexBuffers;

  /// Maximum size in bytes of a single buffer.
  final int maxBufferSize;

  /// Maximum number of vertex attributes.
  final int maxVertexAttributes;

  /// Maximum array stride in bytes for a vertex buffer.
  final int maxVertexBufferArrayStride;

  /// Maximum inter-stage shader variables (varyings).
  final int maxInterStageShaderVariables;

  /// Maximum number of color attachments in a render pass.
  final int maxColorAttachments;

  /// Maximum total bytes per sample across all color attachments.
  final int maxColorAttachmentBytesPerSample;

  /// Maximum bytes of workgroup storage in a compute shader.
  final int maxComputeWorkgroupStorageSize;

  /// Maximum total invocations per workgroup.
  final int maxComputeInvocationsPerWorkgroup;

  /// Maximum workgroup size in the X dimension.
  final int maxComputeWorkgroupSizeX;

  /// Maximum workgroup size in the Y dimension.
  final int maxComputeWorkgroupSizeY;

  /// Maximum workgroup size in the Z dimension.
  final int maxComputeWorkgroupSizeZ;

  /// Maximum workgroups per dimension in a dispatch call.
  final int maxComputeWorkgroupsPerDimension;
}

/// Configuration for requesting a device.
///
/// See [WebGPU spec: GPUDeviceDescriptor](https://www.w3.org/TR/webgpu/#gpudevicedescriptor).
class GpuDeviceDescriptor {
  /// Creates a device descriptor.
  const GpuDeviceDescriptor({
    this.label = '',
    this.requiredFeatures = const {},
    this.requiredLimits,
    this.defaultQueueLabel = '',
  });

  /// Debug label.
  final String label;

  /// Features required on the device.
  final Set<GpuFeatureName> requiredFeatures;

  /// Limits required on the device. Null means use defaults.
  final GpuLimits? requiredLimits;

  /// Label for the device's default queue.
  final String defaultQueueLabel;
}

/// A GPU adapter — represents a physical GPU.
///
/// See [WebGPU spec: GPUAdapter](https://www.w3.org/TR/webgpu/#gpuadapter).
abstract interface class GpuAdapter {
  /// Features supported by this adapter.
  Set<GpuFeatureName> get features;

  /// Hardware limits for this adapter.
  GpuLimits get limits;

  /// Information about this adapter.
  GpuAdapterInfo get info;

  /// Request a device from this adapter.
  Future<GpuDevice> requestDevice([
    GpuDeviceDescriptor descriptor = const GpuDeviceDescriptor(),
  ]);
}
