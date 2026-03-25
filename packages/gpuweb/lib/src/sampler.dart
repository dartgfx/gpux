import 'object_base.dart';

/// Comparison function for depth/stencil tests and samplers.
///
/// See [WebGPU spec: GPUCompareFunction](https://www.w3.org/TR/webgpu/#enumdef-gpucomparefunction).
enum GpuCompareFunction {
  /// Test never passes.
  never,

  /// Passes if new value < current value.
  less,

  /// Passes if new value == current value.
  equal,

  /// Passes if new value <= current value.
  lessEqual,

  /// Passes if new value > current value.
  greater,

  /// Passes if new value != current value.
  notEqual,

  /// Passes if new value >= current value.
  greaterEqual,

  /// Test always passes.
  always,
}

/// A texture sampler.
///
/// See [WebGPU spec: GPUSampler](https://www.w3.org/TR/webgpu/#gpusampler).
abstract interface class GpuSampler implements GpuObjectBase {}

/// Address mode for texture sampling.
///
/// See [WebGPU spec: GPUAddressMode](https://www.w3.org/TR/webgpu/#enumdef-gpuaddressmode).
enum GpuAddressMode {
  /// Clamps texture coordinates to [0, 1].
  clampToEdge,

  /// Repeats the texture by wrapping coordinates.
  repeat,

  /// Repeats the texture, mirroring on each wrap.
  mirrorRepeat,
}

/// Filter mode for texture sampling.
///
/// See [WebGPU spec: GPUFilterMode](https://www.w3.org/TR/webgpu/#enumdef-gpufiltermode).
enum GpuFilterMode {
  /// Returns the nearest texel.
  nearest,

  /// Interpolates between neighboring texels.
  linear,
}

/// Mipmap filter mode.
///
/// See [WebGPU spec: GPUMipmapFilterMode](https://www.w3.org/TR/webgpu/#enumdef-gpumipmapfiltermode).
enum GpuMipmapFilterMode {
  /// Selects the nearest mip level.
  nearest,

  /// Interpolates between mip levels.
  linear,
}

/// Sampler descriptor for creating samplers with specific settings.
///
/// See [WebGPU spec: GPUSamplerDescriptor](https://www.w3.org/TR/webgpu/#dictdef-gpusamplerdescriptor).
class GpuSamplerDescriptor {
  /// Creates a sampler descriptor.
  const GpuSamplerDescriptor({
    this.addressModeU = GpuAddressMode.clampToEdge,
    this.addressModeV = GpuAddressMode.clampToEdge,
    this.addressModeW = GpuAddressMode.clampToEdge,
    this.magFilter = GpuFilterMode.nearest,
    this.minFilter = GpuFilterMode.nearest,
    this.mipmapFilter = GpuMipmapFilterMode.nearest,
    this.lodMinClamp = 0.0,
    this.lodMaxClamp = 32.0,
    this.compare,
    this.maxAnisotropy = 1,
  });

  /// Address mode for the U (horizontal) axis.
  final GpuAddressMode addressModeU;

  /// Address mode for the V (vertical) axis.
  final GpuAddressMode addressModeV;

  /// Address mode for the W (depth) axis.
  final GpuAddressMode addressModeW;

  /// Magnification filter.
  final GpuFilterMode magFilter;

  /// Minification filter.
  final GpuFilterMode minFilter;

  /// Mipmap filter.
  final GpuMipmapFilterMode mipmapFilter;

  /// Minimum level of detail clamp.
  final double lodMinClamp;

  /// Maximum level of detail clamp.
  final double lodMaxClamp;

  /// Comparison function for comparison samplers, or null.
  final GpuCompareFunction? compare;

  /// Maximum anisotropy (1 = disabled).
  final int maxAnisotropy;
}
