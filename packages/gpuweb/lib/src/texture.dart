import 'object_base.dart';

/// Texture formats.
///
/// See [WebGPU spec: GPUTextureFormat](https://www.w3.org/TR/webgpu/#enumdef-gputextureformat).
enum GpuTextureFormat {
  // 8-bit formats

  /// 1-channel, 8-bit unsigned normalized.
  r8Unorm,

  /// 1-channel, 8-bit signed normalized.
  r8Snorm,

  /// 1-channel, 8-bit unsigned integer.
  r8Uint,

  /// 1-channel, 8-bit signed integer.
  r8Sint,

  // 16-bit formats

  /// 1-channel, 16-bit unsigned integer.
  r16Uint,

  /// 1-channel, 16-bit signed integer.
  r16Sint,

  /// 1-channel, 16-bit float.
  r16Float,

  /// 1-channel, 16-bit unsigned normalized.
  r16Unorm,

  /// 1-channel, 16-bit signed normalized.
  r16Snorm,

  /// 2-channel, 8-bit per channel unsigned normalized.
  rg8Unorm,

  /// 2-channel, 8-bit per channel signed normalized.
  rg8Snorm,

  /// 2-channel, 8-bit per channel unsigned integer.
  rg8Uint,

  /// 2-channel, 8-bit per channel signed integer.
  rg8Sint,

  // 32-bit formats

  /// 1-channel, 32-bit unsigned integer.
  r32Uint,

  /// 1-channel, 32-bit signed integer.
  r32Sint,

  /// 1-channel, 32-bit float.
  r32Float,

  /// 2-channel, 16-bit per channel unsigned integer.
  rg16Uint,

  /// 2-channel, 16-bit per channel signed integer.
  rg16Sint,

  /// 2-channel, 16-bit per channel float.
  rg16Float,

  /// 2-channel, 16-bit per channel unsigned normalized.
  rg16Unorm,

  /// 2-channel, 16-bit per channel signed normalized.
  rg16Snorm,

  /// 4-channel, 8-bit per channel unsigned normalized.
  rgba8Unorm,

  /// 4-channel, 8-bit per channel unsigned normalized (sRGB).
  rgba8UnormSrgb,

  /// 4-channel, 8-bit per channel signed normalized.
  rgba8Snorm,

  /// 4-channel, 8-bit per channel unsigned integer.
  rgba8Uint,

  /// 4-channel, 8-bit per channel signed integer.
  rgba8Sint,

  /// 4-channel BGRA, 8-bit per channel unsigned normalized.
  bgra8Unorm,

  /// 4-channel BGRA, 8-bit per channel unsigned normalized (sRGB).
  bgra8UnormSrgb,

  // Packed 32-bit formats

  /// 3-channel, packed 9/9/9-bit with 5-bit shared exponent, unsigned float.
  rgb9e5UFloat,

  /// 4-channel, packed 10/10/10/2-bit unsigned integer.
  rgb10a2Uint,

  /// 4-channel, packed 10/10/10/2-bit unsigned normalized.
  rgb10a2Unorm,

  /// 3-channel, packed 11/11/10-bit unsigned float.
  rg11b10UFloat,

  // 64-bit formats

  /// 2-channel, 32-bit per channel unsigned integer.
  rg32Uint,

  /// 2-channel, 32-bit per channel signed integer.
  rg32Sint,

  /// 2-channel, 32-bit per channel float.
  rg32Float,

  /// 4-channel, 16-bit per channel unsigned integer.
  rgba16Uint,

  /// 4-channel, 16-bit per channel signed integer.
  rgba16Sint,

  /// 4-channel, 16-bit per channel float.
  rgba16Float,

  /// 4-channel, 16-bit per channel unsigned normalized.
  rgba16Unorm,

  /// 4-channel, 16-bit per channel signed normalized.
  rgba16Snorm,

  // 128-bit formats

  /// 4-channel, 32-bit per channel unsigned integer.
  rgba32Uint,

  /// 4-channel, 32-bit per channel signed integer.
  rgba32Sint,

  /// 4-channel, 32-bit per channel float.
  rgba32Float,

  // Depth/stencil formats

  /// 8-bit stencil only.
  stencil8,

  /// 16-bit depth, unsigned normalized.
  depth16Unorm,

  /// 24-bit depth (implementation-chosen format, at least 24 bits).
  depth24Plus,

  /// 24-bit depth + 8-bit stencil.
  depth24PlusStencil8,

  /// 32-bit depth, float.
  depth32Float,

  /// 32-bit float depth + 8-bit stencil. Requires "depth32float-stencil8".
  depth32FloatStencil8,

  // BC compressed formats (require "texture-compression-bc")

  /// BC1 RGBA unsigned normalized (4 bpp).
  bc1RgbaUnorm,

  /// BC1 RGBA unsigned normalized sRGB (4 bpp).
  bc1RgbaUnormSrgb,

  /// BC2 RGBA unsigned normalized (8 bpp).
  bc2RgbaUnorm,

  /// BC2 RGBA unsigned normalized sRGB (8 bpp).
  bc2RgbaUnormSrgb,

  /// BC3 RGBA unsigned normalized (8 bpp).
  bc3RgbaUnorm,

  /// BC3 RGBA unsigned normalized sRGB (8 bpp).
  bc3RgbaUnormSrgb,

  /// BC4 single-channel unsigned normalized (4 bpp).
  bc4RUnorm,

  /// BC4 single-channel signed normalized (4 bpp).
  bc4RSnorm,

  /// BC5 two-channel unsigned normalized (8 bpp).
  bc5RgUnorm,

  /// BC5 two-channel signed normalized (8 bpp).
  bc5RgSnorm,

  /// BC6H three-channel unsigned float (8 bpp, HDR).
  bc6hRgbUFloat,

  /// BC6H three-channel signed float (8 bpp, HDR).
  bc6hRgbFloat,

  /// BC7 RGBA unsigned normalized (8 bpp).
  bc7RgbaUnorm,

  /// BC7 RGBA unsigned normalized sRGB (8 bpp).
  bc7RgbaUnormSrgb,

  // ETC2 compressed formats (require "texture-compression-etc2")

  /// ETC2 RGB unsigned normalized (4 bpp).
  etc2Rgb8Unorm,

  /// ETC2 RGB unsigned normalized sRGB (4 bpp).
  etc2Rgb8UnormSrgb,

  /// ETC2 RGB + 1-bit alpha unsigned normalized (4 bpp).
  etc2Rgb8a1Unorm,

  /// ETC2 RGB + 1-bit alpha unsigned normalized sRGB (4 bpp).
  etc2Rgb8a1UnormSrgb,

  /// ETC2 RGBA unsigned normalized (8 bpp).
  etc2Rgba8Unorm,

  /// ETC2 RGBA unsigned normalized sRGB (8 bpp).
  etc2Rgba8UnormSrgb,

  /// EAC single-channel unsigned normalized (4 bpp).
  eacR11Unorm,

  /// EAC single-channel signed normalized (4 bpp).
  eacR11Snorm,

  /// EAC two-channel unsigned normalized (8 bpp).
  eacRg11Unorm,

  /// EAC two-channel signed normalized (8 bpp).
  eacRg11Snorm,

  // ASTC compressed formats (require "texture-compression-astc")

  /// ASTC 4x4 block unsigned normalized.
  astc4x4Unorm,

  /// ASTC 4x4 block unsigned normalized sRGB.
  astc4x4UnormSrgb,

  /// ASTC 5x4 block unsigned normalized.
  astc5x4Unorm,

  /// ASTC 5x4 block unsigned normalized sRGB.
  astc5x4UnormSrgb,

  /// ASTC 5x5 block unsigned normalized.
  astc5x5Unorm,

  /// ASTC 5x5 block unsigned normalized sRGB.
  astc5x5UnormSrgb,

  /// ASTC 6x5 block unsigned normalized.
  astc6x5Unorm,

  /// ASTC 6x5 block unsigned normalized sRGB.
  astc6x5UnormSrgb,

  /// ASTC 6x6 block unsigned normalized.
  astc6x6Unorm,

  /// ASTC 6x6 block unsigned normalized sRGB.
  astc6x6UnormSrgb,

  /// ASTC 8x5 block unsigned normalized.
  astc8x5Unorm,

  /// ASTC 8x5 block unsigned normalized sRGB.
  astc8x5UnormSrgb,

  /// ASTC 8x6 block unsigned normalized.
  astc8x6Unorm,

  /// ASTC 8x6 block unsigned normalized sRGB.
  astc8x6UnormSrgb,

  /// ASTC 8x8 block unsigned normalized.
  astc8x8Unorm,

  /// ASTC 8x8 block unsigned normalized sRGB.
  astc8x8UnormSrgb,

  /// ASTC 10x5 block unsigned normalized.
  astc10x5Unorm,

  /// ASTC 10x5 block unsigned normalized sRGB.
  astc10x5UnormSrgb,

  /// ASTC 10x6 block unsigned normalized.
  astc10x6Unorm,

  /// ASTC 10x6 block unsigned normalized sRGB.
  astc10x6UnormSrgb,

  /// ASTC 10x8 block unsigned normalized.
  astc10x8Unorm,

  /// ASTC 10x8 block unsigned normalized sRGB.
  astc10x8UnormSrgb,

  /// ASTC 10x10 block unsigned normalized.
  astc10x10Unorm,

  /// ASTC 10x10 block unsigned normalized sRGB.
  astc10x10UnormSrgb,

  /// ASTC 12x10 block unsigned normalized.
  astc12x10Unorm,

  /// ASTC 12x10 block unsigned normalized sRGB.
  astc12x10UnormSrgb,

  /// ASTC 12x12 block unsigned normalized.
  astc12x12Unorm,

  /// ASTC 12x12 block unsigned normalized sRGB.
  astc12x12UnormSrgb,
}

/// A GPU texture.
///
/// See [WebGPU spec: GPUTexture](https://www.w3.org/TR/webgpu/#gputexture).
abstract interface class GpuTexture implements GpuObjectBase {
  /// Width in texels.
  int get width;

  /// Height in texels.
  int get height;

  /// Depth or array layer count.
  int get depthOrArrayLayers;

  /// The texture dimension (1D, 2D, or 3D).
  GpuTextureDimension get dimension;

  /// The texture format.
  GpuTextureFormat get format;

  /// Usage flags this texture was created with.
  int get usage;

  /// Number of mip levels.
  int get mipLevelCount;

  /// Number of samples per texel (1 for non-multisampled).
  int get sampleCount;

  /// The default view dimension for texture bindings using this texture.
  GpuTextureViewDimension get textureBindingViewDimension;

  /// Creates a view into this texture.
  GpuTextureView createView({
    GpuTextureFormat? format,
    GpuTextureViewDimension? dimension,
    GpuTextureUsageFlags? usage,
    int baseMipLevel = 0,
    int? mipLevelCount,
    int baseArrayLayer = 0,
    int? arrayLayerCount,
    GpuTextureAspect aspect = GpuTextureAspect.all,
    String swizzle = 'rgba',
    String label = '',
  });

  /// Destroys the texture, releasing GPU memory.
  void destroy();
}

/// A view into a texture.
///
/// See [WebGPU spec: GPUTextureView](https://www.w3.org/TR/webgpu/#gputextureview).
abstract interface class GpuTextureView implements GpuObjectBase {}

/// Texture dimension.
///
/// See [WebGPU spec: GPUTextureDimension](https://www.w3.org/TR/webgpu/#enumdef-gputexturedimension).
enum GpuTextureDimension {
  /// 1D texture.
  d1,

  /// 2D texture (default).
  d2,

  /// 3D texture.
  d3,
}

/// Texture view dimension.
///
/// See [WebGPU spec: GPUTextureViewDimension](https://www.w3.org/TR/webgpu/#enumdef-gputextureviewdimension).
enum GpuTextureViewDimension {
  /// 1D texture view.
  d1,

  /// 2D texture view.
  d2,

  /// 2D array texture view.
  d2Array,

  /// Cube texture view (6 faces).
  cube,

  /// Cube array texture view.
  cubeArray,

  /// 3D texture view.
  d3,
}

/// Texture aspect.
///
/// See [WebGPU spec: GPUTextureAspect](https://www.w3.org/TR/webgpu/#enumdef-gputextureaspect).
enum GpuTextureAspect {
  /// All aspects of the texture.
  all,

  /// Stencil-only aspect of a depth/stencil texture.
  stencilOnly,

  /// Depth-only aspect of a depth/stencil texture.
  depthOnly,
}

/// Texture usage flags.
///
/// Combine with `|` operator. See [WebGPU spec: GPUTextureUsage](https://www.w3.org/TR/webgpu/#typedefdef-gputextureusageflags).
extension type const GpuTextureUsageFlags(int _) implements int {
  /// Combines this flag with another usage flag.
  GpuTextureUsageFlags operator |(int other) => GpuTextureUsageFlags(_ | other);
}

/// Texture usage flag constants.
///
/// See [WebGPU spec: GPUTextureUsage](https://www.w3.org/TR/webgpu/#typedefdef-gputextureusageflags).
abstract class GpuTextureUsage {
  /// Texture can be used as a copy source.
  static const copySrc = GpuTextureUsageFlags(0x01);

  /// Texture can be used as a copy destination.
  static const copyDst = GpuTextureUsageFlags(0x02);

  /// Texture can be bound as a sampled texture in a shader.
  static const textureBinding = GpuTextureUsageFlags(0x04);

  /// Texture can be bound as a storage texture in a shader.
  static const storageBinding = GpuTextureUsageFlags(0x08);

  /// Texture can be used as a color or depth/stencil attachment.
  static const renderAttachment = GpuTextureUsageFlags(0x10);

  /// Texture may be allocated lazily (tile-based GPUs).
  static const transientAttachment = GpuTextureUsageFlags(0x20);
}
