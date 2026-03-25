import 'package:gpuweb/gpuweb.dart';

/// camelCase → kebab-case. Works for most WebGPU enum string values.
String _toKebab(String camel) =>
    camel.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '-${m[0]!.toLowerCase()}');

String _fromKebab(String kebab) =>
    kebab.replaceAllMapped(RegExp(r'-(\w)'), (m) => m[1]!.toUpperCase());

/// Generic enum → JS string (uses camelCase → kebab-case).
String enumToJs(Enum value) => _toKebab(value.name);

/// Generic JS string → enum (uses kebab-case → camelCase).
T enumFromJs<T extends Enum>(String js, List<T> values) =>
    values.firstWhere((e) => e.name == _fromKebab(js));

String powerPreferenceToJs(GpuPowerPreference p) => enumToJs(p);

GpuPowerPreference powerPreferenceFromJs(String js) =>
    enumFromJs(js, GpuPowerPreference.values);

String textureDimensionToJs(GpuTextureDimension d) => switch (d) {
  GpuTextureDimension.d1 => '1d',
  GpuTextureDimension.d2 => '2d',
  GpuTextureDimension.d3 => '3d',
};

GpuTextureDimension textureDimensionFromJs(String js) => switch (js) {
  '1d' => GpuTextureDimension.d1,
  '2d' => GpuTextureDimension.d2,
  '3d' => GpuTextureDimension.d3,
  _ => throw ArgumentError('Unknown texture dimension: $js'),
};

String textureViewDimensionToJs(GpuTextureViewDimension d) => switch (d) {
  GpuTextureViewDimension.d1 => '1d',
  GpuTextureViewDimension.d2 => '2d',
  GpuTextureViewDimension.d2Array => '2d-array',
  GpuTextureViewDimension.cube => 'cube',
  GpuTextureViewDimension.cubeArray => 'cube-array',
  GpuTextureViewDimension.d3 => '3d',
};

GpuTextureViewDimension textureViewDimensionFromJs(String js) => switch (js) {
  '1d' => GpuTextureViewDimension.d1,
  '2d' => GpuTextureViewDimension.d2,
  '2d-array' => GpuTextureViewDimension.d2Array,
  'cube' => GpuTextureViewDimension.cube,
  'cube-array' => GpuTextureViewDimension.cubeArray,
  '3d' => GpuTextureViewDimension.d3,
  _ => throw ArgumentError('Unknown texture view dimension: $js'),
};

String textureFormatToJs(GpuTextureFormat f) =>
    _textureFormatToJs[f] ?? f.name.toLowerCase();

GpuTextureFormat textureFormatFromJs(String js) {
  final result = _textureFormatFromJs[js];
  if (result != null) return result;
  throw ArgumentError('Unknown texture format: $js');
}

final _textureFormatToJs = <GpuTextureFormat, String>{
  // Simple formats — just lowercase
  GpuTextureFormat.r8Unorm: 'r8unorm',
  GpuTextureFormat.r8Snorm: 'r8snorm',
  GpuTextureFormat.r8Uint: 'r8uint',
  GpuTextureFormat.r8Sint: 'r8sint',
  GpuTextureFormat.r16Uint: 'r16uint',
  GpuTextureFormat.r16Sint: 'r16sint',
  GpuTextureFormat.r16Float: 'r16float',
  GpuTextureFormat.r16Unorm: 'r16unorm',
  GpuTextureFormat.r16Snorm: 'r16snorm',
  GpuTextureFormat.rg8Unorm: 'rg8unorm',
  GpuTextureFormat.rg8Snorm: 'rg8snorm',
  GpuTextureFormat.rg8Uint: 'rg8uint',
  GpuTextureFormat.rg8Sint: 'rg8sint',
  GpuTextureFormat.r32Uint: 'r32uint',
  GpuTextureFormat.r32Sint: 'r32sint',
  GpuTextureFormat.r32Float: 'r32float',
  GpuTextureFormat.rg16Uint: 'rg16uint',
  GpuTextureFormat.rg16Sint: 'rg16sint',
  GpuTextureFormat.rg16Float: 'rg16float',
  GpuTextureFormat.rg16Unorm: 'rg16unorm',
  GpuTextureFormat.rg16Snorm: 'rg16snorm',
  GpuTextureFormat.rgba8Unorm: 'rgba8unorm',
  GpuTextureFormat.rgba8Snorm: 'rgba8snorm',
  GpuTextureFormat.rgba8Uint: 'rgba8uint',
  GpuTextureFormat.rgba8Sint: 'rgba8sint',
  GpuTextureFormat.bgra8Unorm: 'bgra8unorm',
  GpuTextureFormat.rgb9e5UFloat: 'rgb9e5ufloat',
  GpuTextureFormat.rgb10a2Uint: 'rgb10a2uint',
  GpuTextureFormat.rgb10a2Unorm: 'rgb10a2unorm',
  GpuTextureFormat.rg11b10UFloat: 'rg11b10ufloat',
  GpuTextureFormat.rg32Uint: 'rg32uint',
  GpuTextureFormat.rg32Sint: 'rg32sint',
  GpuTextureFormat.rg32Float: 'rg32float',
  GpuTextureFormat.rgba16Uint: 'rgba16uint',
  GpuTextureFormat.rgba16Sint: 'rgba16sint',
  GpuTextureFormat.rgba16Float: 'rgba16float',
  GpuTextureFormat.rgba16Unorm: 'rgba16unorm',
  GpuTextureFormat.rgba16Snorm: 'rgba16snorm',
  GpuTextureFormat.rgba32Uint: 'rgba32uint',
  GpuTextureFormat.rgba32Sint: 'rgba32sint',
  GpuTextureFormat.rgba32Float: 'rgba32float',
  GpuTextureFormat.stencil8: 'stencil8',
  GpuTextureFormat.depth16Unorm: 'depth16unorm',
  GpuTextureFormat.depth24Plus: 'depth24plus',
  GpuTextureFormat.depth32Float: 'depth32float',
  // Hyphenated formats
  GpuTextureFormat.rgba8UnormSrgb: 'rgba8unorm-srgb',
  GpuTextureFormat.bgra8UnormSrgb: 'bgra8unorm-srgb',
  GpuTextureFormat.depth24PlusStencil8: 'depth24plus-stencil8',
  GpuTextureFormat.depth32FloatStencil8: 'depth32float-stencil8',
  // BC compressed
  GpuTextureFormat.bc1RgbaUnorm: 'bc1-rgba-unorm',
  GpuTextureFormat.bc1RgbaUnormSrgb: 'bc1-rgba-unorm-srgb',
  GpuTextureFormat.bc2RgbaUnorm: 'bc2-rgba-unorm',
  GpuTextureFormat.bc2RgbaUnormSrgb: 'bc2-rgba-unorm-srgb',
  GpuTextureFormat.bc3RgbaUnorm: 'bc3-rgba-unorm',
  GpuTextureFormat.bc3RgbaUnormSrgb: 'bc3-rgba-unorm-srgb',
  GpuTextureFormat.bc4RUnorm: 'bc4-r-unorm',
  GpuTextureFormat.bc4RSnorm: 'bc4-r-snorm',
  GpuTextureFormat.bc5RgUnorm: 'bc5-rg-unorm',
  GpuTextureFormat.bc5RgSnorm: 'bc5-rg-snorm',
  GpuTextureFormat.bc6hRgbUFloat: 'bc6h-rgb-ufloat',
  GpuTextureFormat.bc6hRgbFloat: 'bc6h-rgb-float',
  GpuTextureFormat.bc7RgbaUnorm: 'bc7-rgba-unorm',
  GpuTextureFormat.bc7RgbaUnormSrgb: 'bc7-rgba-unorm-srgb',
  // ETC2 compressed
  GpuTextureFormat.etc2Rgb8Unorm: 'etc2-rgb8unorm',
  GpuTextureFormat.etc2Rgb8UnormSrgb: 'etc2-rgb8unorm-srgb',
  GpuTextureFormat.etc2Rgb8a1Unorm: 'etc2-rgb8a1-unorm',
  GpuTextureFormat.etc2Rgb8a1UnormSrgb: 'etc2-rgb8a1-unorm-srgb',
  GpuTextureFormat.etc2Rgba8Unorm: 'etc2-rgba8unorm',
  GpuTextureFormat.etc2Rgba8UnormSrgb: 'etc2-rgba8unorm-srgb',
  GpuTextureFormat.eacR11Unorm: 'eac-r11unorm',
  GpuTextureFormat.eacR11Snorm: 'eac-r11snorm',
  GpuTextureFormat.eacRg11Unorm: 'eac-rg11unorm',
  GpuTextureFormat.eacRg11Snorm: 'eac-rg11snorm',
  // ASTC compressed
  GpuTextureFormat.astc4x4Unorm: 'astc-4x4-unorm',
  GpuTextureFormat.astc4x4UnormSrgb: 'astc-4x4-unorm-srgb',
  GpuTextureFormat.astc5x4Unorm: 'astc-5x4-unorm',
  GpuTextureFormat.astc5x4UnormSrgb: 'astc-5x4-unorm-srgb',
  GpuTextureFormat.astc5x5Unorm: 'astc-5x5-unorm',
  GpuTextureFormat.astc5x5UnormSrgb: 'astc-5x5-unorm-srgb',
  GpuTextureFormat.astc6x5Unorm: 'astc-6x5-unorm',
  GpuTextureFormat.astc6x5UnormSrgb: 'astc-6x5-unorm-srgb',
  GpuTextureFormat.astc6x6Unorm: 'astc-6x6-unorm',
  GpuTextureFormat.astc6x6UnormSrgb: 'astc-6x6-unorm-srgb',
  GpuTextureFormat.astc8x5Unorm: 'astc-8x5-unorm',
  GpuTextureFormat.astc8x5UnormSrgb: 'astc-8x5-unorm-srgb',
  GpuTextureFormat.astc8x6Unorm: 'astc-8x6-unorm',
  GpuTextureFormat.astc8x6UnormSrgb: 'astc-8x6-unorm-srgb',
  GpuTextureFormat.astc8x8Unorm: 'astc-8x8-unorm',
  GpuTextureFormat.astc8x8UnormSrgb: 'astc-8x8-unorm-srgb',
  GpuTextureFormat.astc10x5Unorm: 'astc-10x5-unorm',
  GpuTextureFormat.astc10x5UnormSrgb: 'astc-10x5-unorm-srgb',
  GpuTextureFormat.astc10x6Unorm: 'astc-10x6-unorm',
  GpuTextureFormat.astc10x6UnormSrgb: 'astc-10x6-unorm-srgb',
  GpuTextureFormat.astc10x8Unorm: 'astc-10x8-unorm',
  GpuTextureFormat.astc10x8UnormSrgb: 'astc-10x8-unorm-srgb',
  GpuTextureFormat.astc10x10Unorm: 'astc-10x10-unorm',
  GpuTextureFormat.astc10x10UnormSrgb: 'astc-10x10-unorm-srgb',
  GpuTextureFormat.astc12x10Unorm: 'astc-12x10-unorm',
  GpuTextureFormat.astc12x10UnormSrgb: 'astc-12x10-unorm-srgb',
  GpuTextureFormat.astc12x12Unorm: 'astc-12x12-unorm',
  GpuTextureFormat.astc12x12UnormSrgb: 'astc-12x12-unorm-srgb',
};

final _textureFormatFromJs = {
  for (final e in _textureFormatToJs.entries) e.value: e.key,
};

String vertexFormatToJs(GpuVertexFormat f) => switch (f) {
  GpuVertexFormat.unorm10_10_10_2 => 'unorm10-10-10-2',
  GpuVertexFormat.unorm8x4Bgra => 'unorm8x4-bgra',
  _ => f.name.toLowerCase(),
};

GpuVertexFormat vertexFormatFromJs(String js) => switch (js) {
  'unorm10-10-10-2' => GpuVertexFormat.unorm10_10_10_2,
  'unorm8x4-bgra' => GpuVertexFormat.unorm8x4Bgra,
  _ => GpuVertexFormat.values.firstWhere((e) => e.name.toLowerCase() == js),
};

String featureNameToJs(GpuFeatureName f) => _featureNameToJs[f] ?? enumToJs(f);

GpuFeatureName featureNameFromJs(String js) {
  final result = _featureNameFromJs[js];
  if (result != null) return result;
  return enumFromJs(js, GpuFeatureName.values);
}

final _featureNameToJs = <GpuFeatureName, String>{
  GpuFeatureName.depthClipControl: 'depth-clip-control',
  GpuFeatureName.depth32FloatStencil8: 'depth32float-stencil8',
  GpuFeatureName.textureCompressionBc: 'texture-compression-bc',
  GpuFeatureName.textureCompressionBcSliced3d:
      'texture-compression-bc-sliced-3d',
  GpuFeatureName.textureCompressionEtc2: 'texture-compression-etc2',
  GpuFeatureName.textureCompressionAstc: 'texture-compression-astc',
  GpuFeatureName.textureCompressionAstcSliced3d:
      'texture-compression-astc-sliced-3d',
  GpuFeatureName.timestampQuery: 'timestamp-query',
  GpuFeatureName.indirectFirstInstance: 'indirect-first-instance',
  GpuFeatureName.shaderF16: 'shader-f16',
  GpuFeatureName.rg11b10UfloatRenderable: 'rg11b10ufloat-renderable',
  GpuFeatureName.bgra8UnormStorage: 'bgra8unorm-storage',
  GpuFeatureName.float32Filterable: 'float32-filterable',
  GpuFeatureName.float32Blendable: 'float32-blendable',
  GpuFeatureName.clipDistances: 'clip-distances',
  GpuFeatureName.dualSourceBlending: 'dual-source-blending',
  GpuFeatureName.subgroups: 'subgroups',
  GpuFeatureName.textureFormatsTier1: 'texture-formats-tier-1',
  GpuFeatureName.textureFormatsTier2: 'texture-formats-tier-2',
  GpuFeatureName.primitiveIndex: 'primitive-index',
  GpuFeatureName.textureComponentSwizzle: 'texture-component-swizzle',
};

final _featureNameFromJs = {
  for (final e in _featureNameToJs.entries) e.value: e.key,
};

String wgslFeatureToJs(GpuWgslLanguageFeatureName f) => switch (f) {
  GpuWgslLanguageFeatureName.readonlyAndReadwriteStorageTextures =>
    'readonly_and_readwrite_storage_textures',
  GpuWgslLanguageFeatureName.packed4x8IntegerDotProduct =>
    'packed_4x8_integer_dot_product',
  GpuWgslLanguageFeatureName.unrestrictedPointerParameters =>
    'unrestricted_pointer_parameters',
  GpuWgslLanguageFeatureName.pointerCompositeAccess =>
    'pointer_composite_access',
  GpuWgslLanguageFeatureName.uniformBufferStandardLayout =>
    'uniform_buffer_standard_layout',
  GpuWgslLanguageFeatureName.subgroupId => 'subgroup_id',
  GpuWgslLanguageFeatureName.textureAndSamplerLet => 'texture_and_sampler_let',
  GpuWgslLanguageFeatureName.subgroupUniformity => 'subgroup_uniformity',
};

final _wgslFeatureFromJs = {
  for (final f in GpuWgslLanguageFeatureName.values) wgslFeatureToJs(f): f,
};

GpuWgslLanguageFeatureName wgslFeatureFromJs(String js) {
  final result = _wgslFeatureFromJs[js];
  if (result != null) return result;
  throw ArgumentError('Unknown WGSL language feature: $js');
}

String textureAspectToJs(GpuTextureAspect a) => enumToJs(a);
String loadOpToJs(GpuLoadOp op) => enumToJs(op);
String storeOpToJs(GpuStoreOp op) => enumToJs(op);
String indexFormatToJs(GpuIndexFormat f) => enumToJs(f);
String primitiveTopologyToJs(GpuPrimitiveTopology t) => enumToJs(t);
String frontFaceToJs(GpuFrontFace f) => enumToJs(f);
String cullModeToJs(GpuCullMode m) => enumToJs(m);
String compareFunctionToJs(GpuCompareFunction f) => enumToJs(f);
String stencilOperationToJs(GpuStencilOperation op) => enumToJs(op);
String blendOperationToJs(GpuBlendOperation op) => enumToJs(op);
String blendFactorToJs(GpuBlendFactor f) => enumToJs(f);
String filterModeToJs(GpuFilterMode m) => enumToJs(m);
String mipmapFilterModeToJs(GpuMipmapFilterMode m) => enumToJs(m);
String addressModeToJs(GpuAddressMode m) => enumToJs(m);
String bufferBindingTypeToJs(GpuBufferBindingType t) => enumToJs(t);
String samplerBindingTypeToJs(GpuSamplerBindingType t) => enumToJs(t);
String textureSampleTypeToJs(GpuTextureSampleType t) => enumToJs(t);
String storageTextureAccessToJs(GpuStorageTextureAccess a) => enumToJs(a);
String queryTypeToJs(GpuQueryType t) => enumToJs(t);
String errorFilterToJs(GpuErrorFilter f) => enumToJs(f);
String vertexStepModeToJs(GpuVertexStepMode m) => enumToJs(m);

GpuBufferMapState bufferMapStateFromJs(String js) =>
    enumFromJs(js, GpuBufferMapState.values);
GpuQueryType queryTypeFromJs(String js) => enumFromJs(js, GpuQueryType.values);
GpuDeviceLostReason deviceLostReasonFromJs(String js) =>
    enumFromJs(js, GpuDeviceLostReason.values);
GpuCompilationMessageType compilationMessageTypeFromJs(String js) =>
    enumFromJs(js, GpuCompilationMessageType.values);
