import 'package:gpuweb/gpuweb.dart';

/// FFI integer values for GPU enums.
///
/// These extensions provide the FFI values that match the wgpu/WebGPU spec.

extension GpuBufferBindingTypeFFI on GpuBufferBindingType {
  int get ffiValue => switch (this) {
    GpuBufferBindingType.uniform => 2,
    GpuBufferBindingType.storage => 3,
    GpuBufferBindingType.readOnlyStorage => 4,
  };
}

extension GpuSamplerBindingTypeFFI on GpuSamplerBindingType {
  int get ffiValue => switch (this) {
    GpuSamplerBindingType.filtering => 2,
    GpuSamplerBindingType.nonFiltering => 3,
    GpuSamplerBindingType.comparison => 4,
  };
}

extension GpuTextureSampleTypeFFI on GpuTextureSampleType {
  int get ffiValue => switch (this) {
    GpuTextureSampleType.float => 2,
    GpuTextureSampleType.unfilterableFloat => 3,
    GpuTextureSampleType.depth => 4,
    GpuTextureSampleType.sint => 5,
    GpuTextureSampleType.uint => 6,
  };
}

extension GpuStorageTextureAccessFFI on GpuStorageTextureAccess {
  int get ffiValue => switch (this) {
    GpuStorageTextureAccess.writeOnly => 2,
    GpuStorageTextureAccess.readOnly => 3,
    GpuStorageTextureAccess.readWrite => 4,
  };
}

extension GpuLoadOpFFI on GpuLoadOp {
  int get ffiValue => switch (this) {
    GpuLoadOp.clear => 0,
    GpuLoadOp.load => 1,
  };
}

extension GpuStoreOpFFI on GpuStoreOp {
  int get ffiValue => switch (this) {
    GpuStoreOp.store => 0,
    GpuStoreOp.discard => 1,
  };
}

extension GpuQueryTypeFFI on GpuQueryType {
  int get ffiValue => switch (this) {
    GpuQueryType.occlusion => 1,
    GpuQueryType.timestamp => 2,
  };
}

extension GpuAddressModeFFI on GpuAddressMode {
  int get ffiValue => switch (this) {
    GpuAddressMode.clampToEdge => 0,
    GpuAddressMode.repeat => 1,
    GpuAddressMode.mirrorRepeat => 2,
  };
}

extension GpuFilterModeFFI on GpuFilterMode {
  int get ffiValue => switch (this) {
    GpuFilterMode.nearest => 0,
    GpuFilterMode.linear => 1,
  };
}

extension GpuMipmapFilterModeFFI on GpuMipmapFilterMode {
  int get ffiValue => switch (this) {
    GpuMipmapFilterMode.nearest => 0,
    GpuMipmapFilterMode.linear => 1,
  };
}

extension GpuTextureDimensionFFI on GpuTextureDimension {
  int get ffiValue => switch (this) {
    GpuTextureDimension.d1 => 0,
    GpuTextureDimension.d2 => 1,
    GpuTextureDimension.d3 => 2,
  };
}

extension GpuTextureViewDimensionFFI on GpuTextureViewDimension {
  int get ffiValue => switch (this) {
    GpuTextureViewDimension.d1 => 0,
    GpuTextureViewDimension.d2 => 1,
    GpuTextureViewDimension.d2Array => 2,
    GpuTextureViewDimension.cube => 3,
    GpuTextureViewDimension.cubeArray => 4,
    GpuTextureViewDimension.d3 => 5,
  };
}

extension GpuTextureAspectFFI on GpuTextureAspect {
  int get ffiValue => switch (this) {
    GpuTextureAspect.all => 1,
    GpuTextureAspect.stencilOnly => 2,
    GpuTextureAspect.depthOnly => 3,
  };
}

extension GpuVertexFormatFFI on GpuVertexFormat {
  int get ffiValue => switch (this) {
    GpuVertexFormat.uint8 => 0,
    GpuVertexFormat.uint8x2 => 1,
    GpuVertexFormat.uint8x4 => 2,
    GpuVertexFormat.sint8 => 3,
    GpuVertexFormat.sint8x2 => 4,
    GpuVertexFormat.sint8x4 => 5,
    GpuVertexFormat.unorm8 => 6,
    GpuVertexFormat.unorm8x2 => 7,
    GpuVertexFormat.unorm8x4 => 8,
    GpuVertexFormat.snorm8 => 9,
    GpuVertexFormat.snorm8x2 => 10,
    GpuVertexFormat.snorm8x4 => 11,
    GpuVertexFormat.uint16 => 12,
    GpuVertexFormat.uint16x2 => 13,
    GpuVertexFormat.uint16x4 => 14,
    GpuVertexFormat.sint16 => 15,
    GpuVertexFormat.sint16x2 => 16,
    GpuVertexFormat.sint16x4 => 17,
    GpuVertexFormat.unorm16 => 18,
    GpuVertexFormat.unorm16x2 => 19,
    GpuVertexFormat.unorm16x4 => 20,
    GpuVertexFormat.snorm16 => 21,
    GpuVertexFormat.snorm16x2 => 22,
    GpuVertexFormat.snorm16x4 => 23,
    GpuVertexFormat.float16 => 24,
    GpuVertexFormat.float16x2 => 25,
    GpuVertexFormat.float16x4 => 26,
    GpuVertexFormat.float32 => 27,
    GpuVertexFormat.float32x2 => 28,
    GpuVertexFormat.float32x3 => 29,
    GpuVertexFormat.float32x4 => 30,
    GpuVertexFormat.uint32 => 31,
    GpuVertexFormat.uint32x2 => 32,
    GpuVertexFormat.uint32x3 => 33,
    GpuVertexFormat.uint32x4 => 34,
    GpuVertexFormat.sint32 => 35,
    GpuVertexFormat.sint32x2 => 36,
    GpuVertexFormat.sint32x3 => 37,
    GpuVertexFormat.sint32x4 => 38,
    GpuVertexFormat.unorm10_10_10_2 => 39,
    GpuVertexFormat.unorm8x4Bgra => 40,
  };
}

extension GpuVertexStepModeFFI on GpuVertexStepMode {
  int get ffiValue => switch (this) {
    GpuVertexStepMode.vertex => 0,
    GpuVertexStepMode.instance => 1,
  };
}

final _textureFormatFromFfi = {
  for (final f in GpuTextureFormat.values) f.ffiValue: f,
};

GpuTextureFormat textureFormatFromFfi(int value) =>
    _textureFormatFromFfi[value] ??
    (throw ArgumentError('Unknown texture format FFI value: $value'));

extension GpuTextureFormatFFI on GpuTextureFormat {
  int get ffiValue => switch (this) {
    // 8-bit formats
    GpuTextureFormat.r8Unorm => 0,
    GpuTextureFormat.r8Snorm => 1,
    GpuTextureFormat.r8Uint => 2,
    GpuTextureFormat.r8Sint => 3,
    // 16-bit formats
    GpuTextureFormat.r16Uint => 4,
    GpuTextureFormat.r16Sint => 5,
    GpuTextureFormat.r16Float => 6,
    GpuTextureFormat.r16Unorm => 95,
    GpuTextureFormat.r16Snorm => 96,
    GpuTextureFormat.rg8Unorm => 7,
    GpuTextureFormat.rg8Snorm => 8,
    GpuTextureFormat.rg8Uint => 9,
    GpuTextureFormat.rg8Sint => 10,
    // 32-bit formats
    GpuTextureFormat.r32Uint => 11,
    GpuTextureFormat.r32Sint => 12,
    GpuTextureFormat.r32Float => 13,
    GpuTextureFormat.rg16Uint => 14,
    GpuTextureFormat.rg16Sint => 15,
    GpuTextureFormat.rg16Float => 16,
    GpuTextureFormat.rg16Unorm => 97,
    GpuTextureFormat.rg16Snorm => 98,
    GpuTextureFormat.rgba8Unorm => 17,
    GpuTextureFormat.rgba8UnormSrgb => 18,
    GpuTextureFormat.rgba8Snorm => 19,
    GpuTextureFormat.rgba8Uint => 20,
    GpuTextureFormat.rgba8Sint => 21,
    GpuTextureFormat.bgra8Unorm => 22,
    GpuTextureFormat.bgra8UnormSrgb => 23,
    // Packed 32-bit formats
    GpuTextureFormat.rgb9e5UFloat => 24,
    GpuTextureFormat.rgb10a2Uint => 25,
    GpuTextureFormat.rgb10a2Unorm => 26,
    GpuTextureFormat.rg11b10UFloat => 27,
    // 64-bit formats
    GpuTextureFormat.rg32Uint => 28,
    GpuTextureFormat.rg32Sint => 29,
    GpuTextureFormat.rg32Float => 30,
    GpuTextureFormat.rgba16Uint => 31,
    GpuTextureFormat.rgba16Sint => 32,
    GpuTextureFormat.rgba16Float => 33,
    GpuTextureFormat.rgba16Unorm => 99,
    GpuTextureFormat.rgba16Snorm => 100,
    // 128-bit formats
    GpuTextureFormat.rgba32Uint => 34,
    GpuTextureFormat.rgba32Sint => 35,
    GpuTextureFormat.rgba32Float => 36,
    // Depth/stencil formats
    GpuTextureFormat.stencil8 => 37,
    GpuTextureFormat.depth16Unorm => 38,
    GpuTextureFormat.depth24Plus => 39,
    GpuTextureFormat.depth24PlusStencil8 => 40,
    GpuTextureFormat.depth32Float => 41,
    GpuTextureFormat.depth32FloatStencil8 => 42,
    // BC compressed formats
    GpuTextureFormat.bc1RgbaUnorm => 43,
    GpuTextureFormat.bc1RgbaUnormSrgb => 44,
    GpuTextureFormat.bc2RgbaUnorm => 45,
    GpuTextureFormat.bc2RgbaUnormSrgb => 46,
    GpuTextureFormat.bc3RgbaUnorm => 47,
    GpuTextureFormat.bc3RgbaUnormSrgb => 48,
    GpuTextureFormat.bc4RUnorm => 49,
    GpuTextureFormat.bc4RSnorm => 50,
    GpuTextureFormat.bc5RgUnorm => 51,
    GpuTextureFormat.bc5RgSnorm => 52,
    GpuTextureFormat.bc6hRgbUFloat => 53,
    GpuTextureFormat.bc6hRgbFloat => 54,
    GpuTextureFormat.bc7RgbaUnorm => 55,
    GpuTextureFormat.bc7RgbaUnormSrgb => 56,
    // ETC2 compressed formats
    GpuTextureFormat.etc2Rgb8Unorm => 57,
    GpuTextureFormat.etc2Rgb8UnormSrgb => 58,
    GpuTextureFormat.etc2Rgb8a1Unorm => 59,
    GpuTextureFormat.etc2Rgb8a1UnormSrgb => 60,
    GpuTextureFormat.etc2Rgba8Unorm => 61,
    GpuTextureFormat.etc2Rgba8UnormSrgb => 62,
    GpuTextureFormat.eacR11Unorm => 63,
    GpuTextureFormat.eacR11Snorm => 64,
    GpuTextureFormat.eacRg11Unorm => 65,
    GpuTextureFormat.eacRg11Snorm => 66,
    // ASTC compressed formats
    GpuTextureFormat.astc4x4Unorm => 67,
    GpuTextureFormat.astc4x4UnormSrgb => 68,
    GpuTextureFormat.astc5x4Unorm => 69,
    GpuTextureFormat.astc5x4UnormSrgb => 70,
    GpuTextureFormat.astc5x5Unorm => 71,
    GpuTextureFormat.astc5x5UnormSrgb => 72,
    GpuTextureFormat.astc6x5Unorm => 73,
    GpuTextureFormat.astc6x5UnormSrgb => 74,
    GpuTextureFormat.astc6x6Unorm => 75,
    GpuTextureFormat.astc6x6UnormSrgb => 76,
    GpuTextureFormat.astc8x5Unorm => 77,
    GpuTextureFormat.astc8x5UnormSrgb => 78,
    GpuTextureFormat.astc8x6Unorm => 79,
    GpuTextureFormat.astc8x6UnormSrgb => 80,
    GpuTextureFormat.astc8x8Unorm => 81,
    GpuTextureFormat.astc8x8UnormSrgb => 82,
    GpuTextureFormat.astc10x5Unorm => 83,
    GpuTextureFormat.astc10x5UnormSrgb => 84,
    GpuTextureFormat.astc10x6Unorm => 85,
    GpuTextureFormat.astc10x6UnormSrgb => 86,
    GpuTextureFormat.astc10x8Unorm => 87,
    GpuTextureFormat.astc10x8UnormSrgb => 88,
    GpuTextureFormat.astc10x10Unorm => 89,
    GpuTextureFormat.astc10x10UnormSrgb => 90,
    GpuTextureFormat.astc12x10Unorm => 91,
    GpuTextureFormat.astc12x10UnormSrgb => 92,
    GpuTextureFormat.astc12x12Unorm => 93,
    GpuTextureFormat.astc12x12UnormSrgb => 94,
  };
}

extension GpuCompareFunctionFFI on GpuCompareFunction {
  // 1-indexed: Rust FFI does `value - 1` before lookup, with 0 as sentinel.
  int get ffiValue => switch (this) {
    GpuCompareFunction.never => 1,
    GpuCompareFunction.less => 2,
    GpuCompareFunction.equal => 3,
    GpuCompareFunction.lessEqual => 4,
    GpuCompareFunction.greater => 5,
    GpuCompareFunction.notEqual => 6,
    GpuCompareFunction.greaterEqual => 7,
    GpuCompareFunction.always => 8,
  };
}

extension GpuStencilOperationFFI on GpuStencilOperation {
  int get ffiValue => switch (this) {
    GpuStencilOperation.keep => 0,
    GpuStencilOperation.zero => 1,
    GpuStencilOperation.replace => 2,
    GpuStencilOperation.incrementClamp => 3,
    GpuStencilOperation.decrementClamp => 4,
    GpuStencilOperation.invert => 5,
    GpuStencilOperation.incrementWrap => 6,
    GpuStencilOperation.decrementWrap => 7,
  };
}

extension GpuCullModeFFI on GpuCullMode {
  int get ffiValue => switch (this) {
    GpuCullMode.none => 0,
    GpuCullMode.front => 1,
    GpuCullMode.back => 2,
  };
}

extension GpuBlendOperationFFI on GpuBlendOperation {
  int get ffiValue => switch (this) {
    GpuBlendOperation.add => 0,
    GpuBlendOperation.subtract => 1,
    GpuBlendOperation.reverseSubtract => 2,
    GpuBlendOperation.min => 3,
    GpuBlendOperation.max => 4,
  };
}

extension GpuBlendFactorFFI on GpuBlendFactor {
  int get ffiValue => switch (this) {
    GpuBlendFactor.zero => 0,
    GpuBlendFactor.one => 1,
    GpuBlendFactor.src => 2,
    GpuBlendFactor.oneMinusSrc => 3,
    GpuBlendFactor.srcAlpha => 4,
    GpuBlendFactor.oneMinusSrcAlpha => 5,
    GpuBlendFactor.dst => 6,
    GpuBlendFactor.oneMinusDst => 7,
    GpuBlendFactor.dstAlpha => 8,
    GpuBlendFactor.oneMinusDstAlpha => 9,
    GpuBlendFactor.srcAlphaSaturated => 10,
    GpuBlendFactor.constant => 11,
    GpuBlendFactor.oneMinusConstant => 12,
    GpuBlendFactor.src1 => 13,
    GpuBlendFactor.oneMinusSrc1 => 14,
    GpuBlendFactor.src1Alpha => 15,
    GpuBlendFactor.oneMinusSrc1Alpha => 16,
  };
}

extension GpuPrimitiveTopologyFFI on GpuPrimitiveTopology {
  int get ffiValue => switch (this) {
    GpuPrimitiveTopology.pointList => 0,
    GpuPrimitiveTopology.lineList => 1,
    GpuPrimitiveTopology.lineStrip => 2,
    GpuPrimitiveTopology.triangleList => 3,
    GpuPrimitiveTopology.triangleStrip => 4,
  };
}

extension GpuFrontFaceFFI on GpuFrontFace {
  int get ffiValue => switch (this) {
    GpuFrontFace.ccw => 0,
    GpuFrontFace.cw => 1,
  };
}

extension GpuIndexFormatFFI on GpuIndexFormat {
  int get ffiValue => switch (this) {
    GpuIndexFormat.uint16 => 0,
    GpuIndexFormat.uint32 => 1,
  };
}
