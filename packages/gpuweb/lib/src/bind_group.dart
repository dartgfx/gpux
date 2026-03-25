import 'buffer.dart';
import 'object_base.dart';
import 'sampler.dart';
import 'texture.dart';

/// Buffer binding types.
///
/// See [WebGPU spec: GPUBufferBindingType](https://www.w3.org/TR/webgpu/#enumdef-gpubufferbindingtype).
enum GpuBufferBindingType {
  /// Uniform buffer (read-only, size-limited).
  uniform,

  /// Storage buffer (read-write).
  storage,

  /// Read-only storage buffer.
  readOnlyStorage,
}

/// Shader stage visibility flags.
///
/// Combine with `|` operator.
/// See [WebGPU spec: GPUShaderStage](https://www.w3.org/TR/webgpu/#typedefdef-gpushaderstageflags).
extension type const GpuShaderStageFlags(int _) implements int {
  /// Combines this flag with another stage flag.
  GpuShaderStageFlags operator |(int other) => GpuShaderStageFlags(_ | other);
}

/// Shader stage flag constants.
///
/// See [WebGPU spec: GPUShaderStage](https://www.w3.org/TR/webgpu/#typedefdef-gpushaderstageflags).
abstract class GpuShaderStage {
  /// Visible in the vertex stage.
  static const vertex = GpuShaderStageFlags(0x1);

  /// Visible in the fragment stage.
  static const fragment = GpuShaderStageFlags(0x2);

  /// Visible in the compute stage.
  static const compute = GpuShaderStageFlags(0x4);
}

/// Sampler binding types.
///
/// See [WebGPU spec: GPUSamplerBindingType](https://www.w3.org/TR/webgpu/#enumdef-gpusamplerbindingtype).
enum GpuSamplerBindingType {
  /// Filtering sampler (can interpolate between texels).
  filtering,

  /// Non-filtering sampler (nearest-only).
  nonFiltering,

  /// Comparison sampler (for shadow maps).
  comparison,
}

/// Texture sample types.
///
/// See [WebGPU spec: GPUTextureSampleType](https://www.w3.org/TR/webgpu/#enumdef-gputexturesampletype).
enum GpuTextureSampleType {
  /// Filterable float texture.
  float,

  /// Non-filterable float texture.
  unfilterableFloat,

  /// Depth texture (for comparison sampling).
  depth,

  /// Signed integer texture.
  sint,

  /// Unsigned integer texture.
  uint,
}

/// Storage texture access modes.
///
/// See [WebGPU spec: GPUStorageTextureAccess](https://www.w3.org/TR/webgpu/#enumdef-gpustoragetextureaccess).
enum GpuStorageTextureAccess {
  /// Write-only access.
  writeOnly,

  /// Read-only access.
  readOnly,

  /// Read-write access.
  readWrite,
}

/// A single entry in a bind group layout.
///
/// See [WebGPU spec: GPUBindGroupLayoutEntry](https://www.w3.org/TR/webgpu/#dictdef-gpubindgrouplayoutentry).
sealed class GpuBindGroupLayoutEntry {
  /// Creates a layout entry at the given binding index.
  const GpuBindGroupLayoutEntry({
    required this.binding,
    required this.visibility,
  });

  /// Creates a buffer binding layout entry.
  const factory GpuBindGroupLayoutEntry.buffer({
    required int binding,
    required GpuShaderStageFlags visibility,
    GpuBufferBindingType type,
    bool hasDynamicOffset,
    int minBindingSize,
  }) = GpuBufferBindingLayout;

  /// Creates a sampler binding layout entry.
  const factory GpuBindGroupLayoutEntry.sampler({
    required int binding,
    required GpuShaderStageFlags visibility,
    GpuSamplerBindingType type,
  }) = GpuSamplerBindingLayout;

  /// Creates a texture binding layout entry.
  const factory GpuBindGroupLayoutEntry.texture({
    required int binding,
    required GpuShaderStageFlags visibility,
    GpuTextureSampleType sampleType,
    GpuTextureViewDimension viewDimension,
    bool multisampled,
  }) = GpuTextureBindingLayout;

  /// Creates a storage texture binding layout entry.
  const factory GpuBindGroupLayoutEntry.storageTexture({
    required int binding,
    required GpuTextureFormat format,
    required GpuShaderStageFlags visibility,
    GpuStorageTextureAccess access,
    GpuTextureViewDimension viewDimension,
  }) = GpuStorageTextureBindingLayout;

  /// The binding index this entry corresponds to in the shader.
  final int binding;

  /// Which shader stages can see this binding.
  final GpuShaderStageFlags visibility;
}

/// Buffer binding layout entry.
///
/// See [WebGPU spec: GPUBufferBindingLayout](https://www.w3.org/TR/webgpu/#dictdef-gpubufferbindinglayout).
class GpuBufferBindingLayout extends GpuBindGroupLayoutEntry {
  /// Creates a buffer binding layout.
  const GpuBufferBindingLayout({
    required super.binding,
    required super.visibility,
    this.type = GpuBufferBindingType.uniform,
    this.hasDynamicOffset = false,
    this.minBindingSize = 0,
  });

  /// The buffer binding type.
  final GpuBufferBindingType type;

  /// Whether the buffer offset can be set dynamically via `setBindGroup`.
  final bool hasDynamicOffset;

  /// Minimum required size in bytes (0 means no validation).
  final int minBindingSize;
}

/// Sampler binding layout entry.
///
/// See [WebGPU spec: GPUSamplerBindingLayout](https://www.w3.org/TR/webgpu/#dictdef-gpusamplerbindinglayout).
class GpuSamplerBindingLayout extends GpuBindGroupLayoutEntry {
  /// Creates a sampler binding layout.
  const GpuSamplerBindingLayout({
    required super.binding,
    required super.visibility,
    this.type = GpuSamplerBindingType.filtering,
  });

  /// The sampler binding type.
  final GpuSamplerBindingType type;
}

/// Texture binding layout entry.
///
/// See [WebGPU spec: GPUTextureBindingLayout](https://www.w3.org/TR/webgpu/#dictdef-gputexturebindinglayout).
class GpuTextureBindingLayout extends GpuBindGroupLayoutEntry {
  /// Creates a texture binding layout.
  const GpuTextureBindingLayout({
    required super.binding,
    required super.visibility,
    this.sampleType = GpuTextureSampleType.float,
    this.viewDimension = GpuTextureViewDimension.d2,
    this.multisampled = false,
  });

  /// The texture sample type.
  final GpuTextureSampleType sampleType;

  /// The expected texture view dimension.
  final GpuTextureViewDimension viewDimension;

  /// Whether the texture is multisampled.
  final bool multisampled;
}

/// Storage texture binding layout entry.
///
/// See [WebGPU spec: GPUStorageTextureBindingLayout](https://www.w3.org/TR/webgpu/#dictdef-gpustoragetexturebindinglayout).
class GpuStorageTextureBindingLayout extends GpuBindGroupLayoutEntry {
  /// Creates a storage texture binding layout.
  const GpuStorageTextureBindingLayout({
    required super.binding,
    required this.format,
    required super.visibility,
    this.access = GpuStorageTextureAccess.writeOnly,
    this.viewDimension = GpuTextureViewDimension.d2,
  });

  /// The access mode for the storage texture.
  final GpuStorageTextureAccess access;

  /// The texture format.
  final GpuTextureFormat format;

  /// The expected texture view dimension.
  final GpuTextureViewDimension viewDimension;
}

/// A single entry in a bind group.
///
/// See [WebGPU spec: GPUBindGroupEntry](https://www.w3.org/TR/webgpu/#dictdef-gpubindgroupentry).
abstract class GpuBindGroupEntry {
  /// Creates a bind group entry.
  const GpuBindGroupEntry();

  /// Creates a buffer bind group entry.
  factory GpuBindGroupEntry.buffer({
    required int binding,
    required GpuBuffer buffer,
    int offset,
    int size,
  }) = GpuBufferBinding;

  /// Creates a sampler bind group entry.
  factory GpuBindGroupEntry.sampler({
    required int binding,
    required GpuSampler sampler,
  }) = GpuSamplerBinding;

  /// Creates a texture view bind group entry.
  factory GpuBindGroupEntry.textureView({
    required int binding,
    required GpuTextureView view,
  }) = GpuTextureViewBinding;

  /// The binding index this entry corresponds to.
  int get binding;
}

/// Binds a buffer (or a range of it) to a binding slot.
///
/// See [WebGPU spec: GPUBufferBinding](https://www.w3.org/TR/webgpu/#dictdef-gpubufferbinding).
class GpuBufferBinding extends GpuBindGroupEntry {
  /// Creates a buffer binding.
  const GpuBufferBinding({
    required this.binding,
    required this.buffer,
    this.offset = 0,
    this.size,
  });

  @override
  final int binding;

  /// The buffer to bind.
  final GpuBuffer buffer;

  /// Byte offset into the buffer.
  final int offset;

  /// Number of bytes to bind, or null for the rest of the buffer.
  final int? size;
}

/// Binds a sampler to a binding slot.
class GpuSamplerBinding extends GpuBindGroupEntry {
  /// Creates a sampler binding.
  const GpuSamplerBinding({
    required this.binding,
    required this.sampler,
  });

  @override
  final int binding;

  /// The sampler to bind.
  final GpuSampler sampler;
}

/// Binds a texture view to a binding slot.
class GpuTextureViewBinding extends GpuBindGroupEntry {
  /// Creates a texture view binding.
  GpuTextureViewBinding({required this.binding, required this.view});

  @override
  final int binding;

  /// The texture view to bind.
  final GpuTextureView view;
}

/// A bind group layout defining the interface between resources and shader stages.
///
/// See [WebGPU spec: GPUBindGroupLayout](https://www.w3.org/TR/webgpu/#gpubindgrouplayout).
abstract interface class GpuBindGroupLayout implements GpuObjectBase {}

/// A bind group that binds resources to shader bindings.
///
/// See [WebGPU spec: GPUBindGroup](https://www.w3.org/TR/webgpu/#gpubindgroup).
abstract interface class GpuBindGroup implements GpuObjectBase {}
