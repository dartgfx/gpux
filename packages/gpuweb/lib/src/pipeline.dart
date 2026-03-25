import 'bind_group.dart';
import 'object_base.dart';
import 'sampler.dart' show GpuCompareFunction;
import 'shader.dart';
import 'texture.dart' show GpuTextureFormat;

/// Stencil operations.
///
/// See [WebGPU spec: GPUStencilOperation](https://www.w3.org/TR/webgpu/#enumdef-gpustenciloperation).
enum GpuStencilOperation {
  /// Keeps the current stencil value.
  keep,

  /// Sets the stencil value to 0.
  zero,

  /// Replaces the stencil value with the reference value.
  replace,

  /// Increments and clamps the stencil value.
  incrementClamp,

  /// Decrements and clamps the stencil value.
  decrementClamp,

  /// Bitwise inverts the stencil value.
  invert,

  /// Increments the stencil value, wrapping to 0 on overflow.
  incrementWrap,

  /// Decrements the stencil value, wrapping to max on underflow.
  decrementWrap,
}

/// Face culling mode.
///
/// See [WebGPU spec: GPUCullMode](https://www.w3.org/TR/webgpu/#enumdef-gpucullmode).
enum GpuCullMode {
  /// No culling.
  none,

  /// Cull front-facing triangles.
  front,

  /// Cull back-facing triangles.
  back,
}

/// Blend operations.
///
/// See [WebGPU spec: GPUBlendOperation](https://www.w3.org/TR/webgpu/#enumdef-gpublendoperation).
enum GpuBlendOperation {
  /// `src + dst`.
  add,

  /// `src - dst`.
  subtract,

  /// `dst - src`.
  reverseSubtract,

  /// `min(src, dst)`.
  min,

  /// `max(src, dst)`.
  max,
}

/// Blend factors.
///
/// See [WebGPU spec: GPUBlendFactor](https://www.w3.org/TR/webgpu/#enumdef-gpublendfactor).
enum GpuBlendFactor {
  /// Factor is 0.
  zero,

  /// Factor is 1.
  one,

  /// Factor is source color/alpha.
  src,

  /// Factor is `1 - source`.
  oneMinusSrc,

  /// Factor is source alpha.
  srcAlpha,

  /// Factor is `1 - source alpha`.
  oneMinusSrcAlpha,

  /// Factor is destination color/alpha.
  dst,

  /// Factor is `1 - destination`.
  oneMinusDst,

  /// Factor is destination alpha.
  dstAlpha,

  /// Factor is `1 - destination alpha`.
  oneMinusDstAlpha,

  /// Factor is `min(source alpha, 1 - destination alpha)`.
  srcAlphaSaturated,

  /// Factor is the blend constant.
  constant,

  /// Factor is `1 - blend constant`.
  oneMinusConstant,

  /// Factor is second source color/alpha. Requires "dual-source-blending".
  src1,

  /// Factor is `1 - second source`. Requires "dual-source-blending".
  oneMinusSrc1,

  /// Factor is second source alpha. Requires "dual-source-blending".
  src1Alpha,

  /// Factor is `1 - second source alpha`. Requires "dual-source-blending".
  oneMinusSrc1Alpha,
}

/// Primitive topology.
///
/// See [WebGPU spec: GPUPrimitiveTopology](https://www.w3.org/TR/webgpu/#enumdef-gputrimitivetopology).
enum GpuPrimitiveTopology {
  /// Each vertex is a separate point.
  pointList,

  /// Every two vertices form a line.
  lineList,

  /// Vertices form a connected strip of lines.
  lineStrip,

  /// Every three vertices form a triangle (default).
  triangleList,

  /// Vertices form a connected strip of triangles.
  triangleStrip,
}

/// Front face winding order.
///
/// See [WebGPU spec: GPUFrontFace](https://www.w3.org/TR/webgpu/#enumdef-gpufrontface).
enum GpuFrontFace {
  /// Counter-clockwise winding (default).
  ccw,

  /// Clockwise winding.
  cw,
}

/// Index format.
///
/// See [WebGPU spec: GPUIndexFormat](https://www.w3.org/TR/webgpu/#enumdef-gpuindexformat).
enum GpuIndexFormat {
  /// 16-bit unsigned integer indices (2 bytes each).
  uint16,

  /// 32-bit unsigned integer indices (4 bytes each).
  uint32,
}

/// A pipeline layout that groups bind group layouts.
///
/// See [WebGPU spec: GPUPipelineLayout](https://www.w3.org/TR/webgpu/#gpupipelinelayout).
abstract interface class GpuPipelineLayout implements GpuObjectBase {}

/// A render pipeline.
///
/// See [WebGPU spec: GPURenderPipeline](https://www.w3.org/TR/webgpu/#gpurenderpipeline).
abstract interface class GpuRenderPipeline implements GpuObjectBase {
  /// Returns the bind group layout at the given index.
  GpuBindGroupLayout getBindGroupLayout(int index);
}

/// A compute pipeline.
///
/// See [WebGPU spec: GPUComputePipeline](https://www.w3.org/TR/webgpu/#gpucomputepipeline).
abstract interface class GpuComputePipeline implements GpuObjectBase {
  /// Returns the bind group layout at the given index.
  GpuBindGroupLayout getBindGroupLayout(int index);
}

/// Vertex formats.
///
/// Each value specifies the data type and number of components per vertex
/// attribute. See [WebGPU spec: GPUVertexFormat](https://www.w3.org/TR/webgpu/#enumdef-gpuvertexformat).
enum GpuVertexFormat {
  /// 1-component, 8-bit unsigned integer.
  uint8,

  /// 2-component, 8-bit unsigned integer.
  uint8x2,

  /// 4-component, 8-bit unsigned integer.
  uint8x4,

  /// 1-component, 8-bit signed integer.
  sint8,

  /// 2-component, 8-bit signed integer.
  sint8x2,

  /// 4-component, 8-bit signed integer.
  sint8x4,

  /// 1-component, 8-bit unsigned normalized.
  unorm8,

  /// 2-component, 8-bit unsigned normalized.
  unorm8x2,

  /// 4-component, 8-bit unsigned normalized.
  unorm8x4,

  /// 1-component, 8-bit signed normalized.
  snorm8,

  /// 2-component, 8-bit signed normalized.
  snorm8x2,

  /// 4-component, 8-bit signed normalized.
  snorm8x4,

  /// 1-component, 16-bit unsigned integer.
  uint16,

  /// 2-component, 16-bit unsigned integer.
  uint16x2,

  /// 4-component, 16-bit unsigned integer.
  uint16x4,

  /// 1-component, 16-bit signed integer.
  sint16,

  /// 2-component, 16-bit signed integer.
  sint16x2,

  /// 4-component, 16-bit signed integer.
  sint16x4,

  /// 1-component, 16-bit unsigned normalized.
  unorm16,

  /// 2-component, 16-bit unsigned normalized.
  unorm16x2,

  /// 4-component, 16-bit unsigned normalized.
  unorm16x4,

  /// 1-component, 16-bit signed normalized.
  snorm16,

  /// 2-component, 16-bit signed normalized.
  snorm16x2,

  /// 4-component, 16-bit signed normalized.
  snorm16x4,

  /// 1-component, 16-bit float.
  float16,

  /// 2-component, 16-bit float.
  float16x2,

  /// 4-component, 16-bit float.
  float16x4,

  /// 1-component, 32-bit float.
  float32,

  /// 2-component, 32-bit float.
  float32x2,

  /// 3-component, 32-bit float.
  float32x3,

  /// 4-component, 32-bit float.
  float32x4,

  /// 1-component, 32-bit unsigned integer.
  uint32,

  /// 2-component, 32-bit unsigned integer.
  uint32x2,

  /// 3-component, 32-bit unsigned integer.
  uint32x3,

  /// 4-component, 32-bit unsigned integer.
  uint32x4,

  /// 1-component, 32-bit signed integer.
  sint32,

  /// 2-component, 32-bit signed integer.
  sint32x2,

  /// 3-component, 32-bit signed integer.
  sint32x3,

  /// 4-component, 32-bit signed integer.
  sint32x4,

  /// 4-component, packed 10/10/10/2-bit unsigned normalized.
  unorm10_10_10_2,

  /// 4-component BGRA, 8-bit unsigned normalized.
  unorm8x4Bgra,
}

/// Vertex step modes.
///
/// See [WebGPU spec: GPUVertexStepMode](https://www.w3.org/TR/webgpu/#enumdef-gpuvertexstepmode).
enum GpuVertexStepMode {
  /// Attribute advances per vertex.
  vertex,

  /// Attribute advances per instance.
  instance,
}

/// A vertex attribute in a vertex buffer layout.
///
/// See [WebGPU spec: GPUVertexAttribute](https://www.w3.org/TR/webgpu/#dictdef-gpuvertexattribute).
class GpuVertexAttribute {
  /// Creates a vertex attribute.
  const GpuVertexAttribute({
    required this.format,
    required this.offset,
    required this.shaderLocation,
  });

  /// The vertex format for this attribute.
  final GpuVertexFormat format;

  /// Byte offset from the start of the vertex buffer element.
  final int offset;

  /// The shader location this attribute maps to (`@location(n)`).
  final int shaderLocation;
}

/// A vertex buffer layout.
///
/// See [WebGPU spec: GPUVertexBufferLayout](https://www.w3.org/TR/webgpu/#dictdef-gpuvertexbufferlayout).
class GpuVertexBufferLayout {
  /// Creates a vertex buffer layout.
  const GpuVertexBufferLayout({
    required this.arrayStride,
    this.stepMode = GpuVertexStepMode.vertex,
    required this.attributes,
  });

  /// Stride in bytes between consecutive elements.
  final int arrayStride;

  /// Whether the buffer steps per vertex or per instance.
  final GpuVertexStepMode stepMode;

  /// The attributes within this buffer layout.
  final List<GpuVertexAttribute> attributes;
}

/// Color write mask bits.
///
/// See [WebGPU spec: GPUColorWrite](https://www.w3.org/TR/webgpu/#typedefdef-gpucolorwriteflags).
class GpuColorWrite {
  /// Write the red channel.
  static const red = 1;

  /// Write the green channel.
  static const green = 2;

  /// Write the blue channel.
  static const blue = 4;

  /// Write the alpha channel.
  static const alpha = 8;

  /// Write all channels.
  static const int all = red | green | blue | alpha;
}

/// Blend component (for color or alpha).
///
/// See [WebGPU spec: GPUBlendComponent](https://www.w3.org/TR/webgpu/#dictdef-gpublendcomponent).
class GpuBlendComponent {
  /// Creates a blend component with default additive blending.
  const GpuBlendComponent({
    this.operation = GpuBlendOperation.add,
    this.srcFactor = GpuBlendFactor.one,
    this.dstFactor = GpuBlendFactor.zero,
  });

  /// The blend operation to apply.
  final GpuBlendOperation operation;

  /// Multiplier for the source value.
  final GpuBlendFactor srcFactor;

  /// Multiplier for the destination value.
  final GpuBlendFactor dstFactor;
}

/// Blend state for a color target.
///
/// See [WebGPU spec: GPUBlendState](https://www.w3.org/TR/webgpu/#dictdef-gpublendstate).
class GpuBlendState {
  /// Creates a blend state.
  const GpuBlendState({
    required this.color,
    required this.alpha,
  });

  /// Blend component for color channels.
  final GpuBlendComponent color;

  /// Blend component for the alpha channel.
  final GpuBlendComponent alpha;
}

/// Color target state.
///
/// See [WebGPU spec: GPUColorTargetState](https://www.w3.org/TR/webgpu/#dictdef-gpucolortargetstate).
class GpuColorTargetState {
  /// Creates a color target state.
  const GpuColorTargetState({
    required this.format,
    this.blend,
    this.writeMask = GpuColorWrite.all,
  });

  /// The texture format for this target.
  final GpuTextureFormat format;

  /// Blend state, or null to disable blending.
  final GpuBlendState? blend;

  /// Bitmask controlling which color channels are written.
  final int writeMask;
}

/// Stencil face state.
///
/// See [WebGPU spec: GPUStencilFaceState](https://www.w3.org/TR/webgpu/#dictdef-gpustencilfacestate).
class GpuStencilFaceState {
  /// Creates a stencil face state with defaults that always pass and keep.
  const GpuStencilFaceState({
    this.compare = GpuCompareFunction.always,
    this.failOp = GpuStencilOperation.keep,
    this.depthFailOp = GpuStencilOperation.keep,
    this.passOp = GpuStencilOperation.keep,
  });

  /// Comparison function for the stencil test.
  final GpuCompareFunction compare;

  /// Operation when the stencil test fails.
  final GpuStencilOperation failOp;

  /// Operation when the stencil test passes but depth fails.
  final GpuStencilOperation depthFailOp;

  /// Operation when both stencil and depth tests pass.
  final GpuStencilOperation passOp;
}

/// Depth stencil state.
///
/// See [WebGPU spec: GPUDepthStencilState](https://www.w3.org/TR/webgpu/#dictdef-gpudepthstencilstate).
class GpuDepthStencilState {
  /// Creates a depth stencil state.
  const GpuDepthStencilState({
    required this.format,
    this.depthWriteEnabled,
    this.depthCompare,
    this.depthBias = 0,
    this.depthBiasSlopeScale = 0.0,
    this.depthBiasClamp = 0.0,
    this.stencilFront = const GpuStencilFaceState(),
    this.stencilBack = const GpuStencilFaceState(),
    this.stencilReadMask = 0xFFFFFFFF,
    this.stencilWriteMask = 0xFFFFFFFF,
  });

  /// The depth/stencil texture format.
  final GpuTextureFormat format;

  /// Whether depth values are written. Required if format has depth.
  final bool? depthWriteEnabled;

  /// Comparison function for the depth test. Required if format has depth.
  final GpuCompareFunction? depthCompare;

  /// Constant depth bias added to each fragment.
  final int depthBias;

  /// Depth bias that scales with the fragment's slope.
  final double depthBiasSlopeScale;

  /// Maximum depth bias for a fragment.
  final double depthBiasClamp;

  /// Stencil state for front-facing triangles.
  final GpuStencilFaceState stencilFront;

  /// Stencil state for back-facing triangles.
  final GpuStencilFaceState stencilBack;

  /// Bitmask for reading stencil values.
  final int stencilReadMask;

  /// Bitmask for writing stencil values.
  final int stencilWriteMask;
}

/// Render pipeline descriptor.
///
/// See [WebGPU spec: GPURenderPipelineDescriptor](https://www.w3.org/TR/webgpu/#dictdef-gpurenderpipelinedescriptor).
class GpuRenderPipelineDescriptor {
  /// Creates a render pipeline descriptor.
  const GpuRenderPipelineDescriptor({
    this.label = '',
    required this.layout,
    required this.vertexModule,
    this.vertexEntryPoint,
    this.vertexConstants = const {},
    this.vertexBuffers = const [],
    this.fragmentModule,
    this.fragmentEntryPoint,
    this.fragmentConstants = const {},
    this.colorTargets = const [],
    this.primitiveTopology = GpuPrimitiveTopology.triangleList,
    this.stripIndexFormat,
    this.frontFace = GpuFrontFace.ccw,
    this.cullMode = GpuCullMode.none,
    this.unclippedDepth = false,
    this.depthStencil,
    this.multisampleCount = 1,
    this.multisampleMask = 0xFFFFFFFF,
    this.alphaToCoverageEnabled = false,
  });

  /// Debug label.
  final String label;

  /// Pipeline layout, or null for auto layout.
  final GpuPipelineLayout? layout;

  /// Shader module containing the vertex entry point.
  final GpuShaderModule vertexModule;

  /// Vertex shader entry point name, or null for default.
  final String? vertexEntryPoint;

  /// Pipeline-overridable constants for the vertex stage.
  final Map<String, double> vertexConstants;

  /// Vertex buffer layouts. Null elements are gaps in the slot numbering.
  final List<GpuVertexBufferLayout?> vertexBuffers;

  /// Shader module containing the fragment entry point, or null.
  final GpuShaderModule? fragmentModule;

  /// Fragment shader entry point name, or null for default.
  final String? fragmentEntryPoint;

  /// Pipeline-overridable constants for the fragment stage.
  final Map<String, double> fragmentConstants;

  /// Color targets for the fragment stage. Null elements disable that slot.
  final List<GpuColorTargetState?> colorTargets;

  /// Primitive topology.
  final GpuPrimitiveTopology primitiveTopology;

  /// Index format for strip topologies, or null for list topologies.
  final GpuIndexFormat? stripIndexFormat;

  /// Front face winding order.
  final GpuFrontFace frontFace;

  /// Face culling mode.
  final GpuCullMode cullMode;

  /// Whether depth clipping is disabled. Requires "depth-clip-control".
  final bool unclippedDepth;

  /// Depth/stencil state, or null to disable.
  final GpuDepthStencilState? depthStencil;

  /// Number of samples per pixel for multisampling.
  final int multisampleCount;

  /// Bitmask controlling which samples are active.
  final int multisampleMask;

  /// Whether alpha-to-coverage is enabled.
  final bool alphaToCoverageEnabled;
}
