import 'bind_group.dart';
import 'buffer.dart';
import 'object_base.dart';
import 'pipeline.dart';
import 'query_set.dart';
import 'texture.dart';

/// A command encoder for recording GPU commands.
///
/// See [WebGPU spec: GPUCommandEncoder](https://www.w3.org/TR/webgpu/#gpucommandencoder).
abstract interface class GpuCommandEncoder implements GpuObjectBase {
  /// Begins a render pass.
  GpuRenderPassEncoder beginRenderPass({
    required List<GpuColorAttachment> colorAttachments,
    GpuDepthStencilAttachment? depthStencilAttachment,
    GpuQuerySet? occlusionQuerySet,
    GpuRenderPassTimestampWrites? timestampWrites,
    int maxDrawCount = 50000000,
    String label = '',
  });

  /// Begins a compute pass.
  GpuComputePassEncoder beginComputePass({
    GpuComputePassTimestampWrites? timestampWrites,
    String label = '',
  });

  /// Copies data from one buffer to another.
  void copyBufferToBuffer({
    required GpuBuffer source,
    int sourceOffset = 0,
    required GpuBuffer destination,
    int destinationOffset = 0,
    required int size,
  });

  /// Clears a buffer to zeros.
  ///
  /// If [size] is null, clears from [offset] to the end of the buffer.
  void clearBuffer(GpuBuffer buffer, {int offset = 0, int? size});

  /// Copies data from a texture to a buffer.
  void copyTextureToBuffer({
    required GpuTexture source,
    required GpuBuffer destination,
    required int bytesPerRow,
    required int width,
    required int height,
    int? rowsPerImage,
    int depth = 1,
    int mipLevel = 0,
    int originX = 0,
    int originY = 0,
    int originZ = 0,
  });

  /// Copies data from a buffer to a texture.
  void copyBufferToTexture({
    required GpuBuffer source,
    required GpuTexture destination,
    required int bytesPerRow,
    required int width,
    required int height,
    int? rowsPerImage,
    int depth = 1,
    int mipLevel = 0,
    int originX = 0,
    int originY = 0,
    int originZ = 0,
  });

  /// Copies data from one texture to another.
  void copyTextureToTexture({
    required GpuTexture source,
    required GpuTexture destination,
    required int width,
    required int height,
    int depth = 1,
    int srcMipLevel = 0,
    int srcOriginX = 0,
    int srcOriginY = 0,
    int srcOriginZ = 0,
    int dstMipLevel = 0,
    int dstOriginX = 0,
    int dstOriginY = 0,
    int dstOriginZ = 0,
  });

  /// Resolves query set results to a buffer.
  void resolveQuerySet(
    GpuQuerySet querySet, {
    required int firstQuery,
    required int queryCount,
    required GpuBuffer destination,
    int destinationOffset = 0,
  });

  /// Inserts a debug marker into the command stream.
  void insertDebugMarker(String label);

  /// Begins a named debug group.
  void pushDebugGroup(String label);

  /// Ends the current debug group.
  void popDebugGroup();

  /// Finishes recording and returns a command buffer.
  GpuCommandBuffer finish({String label = ''});
}

/// A render pass encoder for recording draw commands.
///
/// See [WebGPU spec: GPURenderPassEncoder](https://www.w3.org/TR/webgpu/#gpurenderpassencoder).
abstract interface class GpuRenderPassEncoder implements GpuObjectBase {
  /// Sets the current render pipeline.
  void setPipeline(GpuRenderPipeline pipeline);

  /// Binds a bind group at the given index.
  void setBindGroup(
    int index,
    GpuBindGroup bindGroup, {
    List<int>? dynamicOffsets,
  });

  /// Binds a vertex buffer to the given slot, or null to unbind.
  void setVertexBuffer(
    int slot,
    GpuBuffer? buffer, {
    int offset = 0,
    int? size,
  });

  /// Sets the index buffer.
  void setIndexBuffer(
    GpuBuffer buffer,
    GpuIndexFormat format, {
    int offset = 0,
    int? size,
  });

  /// Draws primitives.
  void draw({
    required int vertexCount,
    int instanceCount = 1,
    int firstVertex = 0,
    int firstInstance = 0,
  });

  /// Draws indexed primitives.
  void drawIndexed({
    required int indexCount,
    int instanceCount = 1,
    int firstIndex = 0,
    int baseVertex = 0,
    int firstInstance = 0,
  });

  /// Draws primitives using parameters from a buffer.
  void drawIndirect(GpuBuffer indirectBuffer, {int indirectOffset = 0});

  /// Draws indexed primitives using parameters from a buffer.
  void drawIndexedIndirect(
    GpuBuffer indirectBuffer, {
    int indirectOffset = 0,
  });

  /// Begins an occlusion query at the given index.
  void beginOcclusionQuery(int queryIndex);

  /// Ends the current occlusion query.
  void endOcclusionQuery();

  /// Sets the viewport rectangle and depth range.
  void setViewport(
    double x,
    double y,
    double width,
    double height, {
    double minDepth = 0.0,
    double maxDepth = 1.0,
  });

  /// Sets the scissor rectangle.
  void setScissorRect(int x, int y, int width, int height);

  /// Sets the blend constant color.
  void setBlendConstant(GpuColor color);

  /// Sets the stencil reference value.
  void setStencilReference(int reference);

  /// Inserts a debug marker into the command stream.
  void insertDebugMarker(String label);

  /// Begins a named debug group.
  void pushDebugGroup(String label);

  /// Ends the current debug group.
  void popDebugGroup();

  /// Executes pre-recorded render bundles.
  void executeBundles(List<GpuRenderBundle> bundles);

  /// Ends the render pass.
  void end();
}

/// A compute pass encoder for recording compute dispatch commands.
///
/// See [WebGPU spec: GPUComputePassEncoder](https://www.w3.org/TR/webgpu/#gpucomputepassencoder).
abstract interface class GpuComputePassEncoder implements GpuObjectBase {
  /// Sets the current compute pipeline.
  void setPipeline(GpuComputePipeline pipeline);

  /// Binds a bind group at the given index.
  void setBindGroup(
    int index,
    GpuBindGroup bindGroup, {
    List<int>? dynamicOffsets,
  });

  /// Dispatches workgroups.
  void dispatchWorkgroups(int x, [int y = 1, int z = 1]);

  /// Dispatches workgroups using parameters from a buffer.
  void dispatchWorkgroupsIndirect(GpuBuffer buffer, {int offset = 0});

  /// Inserts a debug marker into the command stream.
  void insertDebugMarker(String label);

  /// Begins a named debug group.
  void pushDebugGroup(String label);

  /// Ends the current debug group.
  void popDebugGroup();

  /// Ends the compute pass.
  void end();
}

/// A recorded command buffer ready for submission.
///
/// See [WebGPU spec: GPUCommandBuffer](https://www.w3.org/TR/webgpu/#gpucommandbuffer).
abstract interface class GpuCommandBuffer implements GpuObjectBase {}

/// Color attachment for a render pass.
///
/// See [WebGPU spec: GPURenderPassColorAttachment](https://www.w3.org/TR/webgpu/#dictdef-gpurenderpasscolorattachment).
class GpuColorAttachment {
  /// Creates a color attachment.
  const GpuColorAttachment({
    required this.view,
    this.resolveTarget,
    required this.loadOp,
    required this.storeOp,
    this.clearValue,
    this.depthSlice,
  });

  /// The texture view to render into.
  final GpuTextureView view;

  /// Multisampled resolve target, or null.
  final GpuTextureView? resolveTarget;

  /// How to initialize the attachment at the start of the pass.
  final GpuLoadOp loadOp;

  /// What to do with the attachment at the end of the pass.
  final GpuStoreOp storeOp;

  /// Clear color when [loadOp] is [GpuLoadOp.clear].
  final GpuColor? clearValue;

  /// The slice of a 3D texture to render into, or null.
  final int? depthSlice;
}

/// Depth/stencil attachment for a render pass.
///
/// See [WebGPU spec: GPURenderPassDepthStencilAttachment](https://www.w3.org/TR/webgpu/#dictdef-gpurenderpassdepthstencilattachment).
class GpuDepthStencilAttachment {
  /// Creates a depth/stencil attachment.
  const GpuDepthStencilAttachment({
    required this.view,
    this.depthLoadOp,
    this.depthStoreOp,
    this.depthClearValue,
    this.depthReadOnly = false,
    this.stencilLoadOp,
    this.stencilStoreOp,
    this.stencilClearValue = 0,
    this.stencilReadOnly = false,
  });

  /// The depth/stencil texture view.
  final GpuTextureView view;

  /// How to initialize depth at the start of the pass.
  final GpuLoadOp? depthLoadOp;

  /// What to do with depth at the end of the pass.
  final GpuStoreOp? depthStoreOp;

  /// Clear depth value when [depthLoadOp] is [GpuLoadOp.clear].
  final double? depthClearValue;

  /// Whether the depth attachment is read-only.
  final bool depthReadOnly;

  /// How to initialize stencil at the start of the pass.
  final GpuLoadOp? stencilLoadOp;

  /// What to do with stencil at the end of the pass.
  final GpuStoreOp? stencilStoreOp;

  /// Clear stencil value when [stencilLoadOp] is [GpuLoadOp.clear].
  final int stencilClearValue;

  /// Whether the stencil attachment is read-only.
  final bool stencilReadOnly;
}

/// RGBA color.
///
/// See [WebGPU spec: GPUColorDict](https://www.w3.org/TR/webgpu/#dictdef-gpucolordict).
class GpuColor {
  /// Creates a color from RGBA components.
  const GpuColor(this.r, this.g, this.b, this.a);

  /// Red component.
  final double r;

  /// Green component.
  final double g;

  /// Blue component.
  final double b;

  /// Alpha component.
  final double a;
}

/// Load operation for attachments.
///
/// See [WebGPU spec: GPULoadOp](https://www.w3.org/TR/webgpu/#enumdef-gpuloadop).
enum GpuLoadOp {
  /// Clears the attachment to a specified value.
  clear,

  /// Loads the existing contents of the attachment.
  load,
}

/// Store operation for attachments.
///
/// See [WebGPU spec: GPUStoreOp](https://www.w3.org/TR/webgpu/#enumdef-gpustoreop).
enum GpuStoreOp {
  /// Stores the result of the pass into the attachment.
  store,

  /// Discards the result (contents become undefined).
  discard,
}

/// A pre-recorded bundle of render commands.
///
/// See [WebGPU spec: GPURenderBundle](https://www.w3.org/TR/webgpu/#gpurenderbundle).
abstract interface class GpuRenderBundle implements GpuObjectBase {}

/// Encoder for recording render bundle commands.
///
/// See [WebGPU spec: GPURenderBundleEncoder](https://www.w3.org/TR/webgpu/#gpurenderbundleencoder).
abstract interface class GpuRenderBundleEncoder implements GpuObjectBase {
  /// Sets the current render pipeline.
  void setPipeline(GpuRenderPipeline pipeline);

  /// Binds a bind group at the given index.
  void setBindGroup(
    int index,
    GpuBindGroup bindGroup, {
    List<int>? dynamicOffsets,
  });

  /// Binds a vertex buffer to the given slot, or null to unbind.
  void setVertexBuffer(
    int slot,
    GpuBuffer? buffer, {
    int offset = 0,
    int? size,
  });

  /// Sets the index buffer.
  void setIndexBuffer(
    GpuBuffer buffer,
    GpuIndexFormat format, {
    int offset = 0,
    int? size,
  });

  /// Draws primitives.
  void draw({
    required int vertexCount,
    int instanceCount = 1,
    int firstVertex = 0,
    int firstInstance = 0,
  });

  /// Draws indexed primitives.
  void drawIndexed({
    required int indexCount,
    int instanceCount = 1,
    int firstIndex = 0,
    int baseVertex = 0,
    int firstInstance = 0,
  });

  /// Draws primitives using parameters from a buffer.
  void drawIndirect(GpuBuffer indirectBuffer, {int indirectOffset = 0});

  /// Draws indexed primitives using parameters from a buffer.
  void drawIndexedIndirect(
    GpuBuffer indirectBuffer, {
    int indirectOffset = 0,
  });

  /// Inserts a debug marker into the command stream.
  void insertDebugMarker(String label);

  /// Begins a named debug group.
  void pushDebugGroup(String label);

  /// Ends the current debug group.
  void popDebugGroup();

  /// Finishes recording and returns a render bundle.
  GpuRenderBundle finish({String label = ''});
}

/// Descriptor for creating a render bundle encoder.
///
/// See [WebGPU spec: GPURenderBundleEncoderDescriptor](https://www.w3.org/TR/webgpu/#dictdef-gpurenderbundleencoderdescriptor).
class GpuRenderBundleEncoderDescriptor {
  /// Creates a render bundle encoder descriptor.
  const GpuRenderBundleEncoderDescriptor({
    required this.colorFormats,
    this.depthStencilFormat,
    this.sampleCount = 1,
    this.depthReadOnly = false,
    this.stencilReadOnly = false,
    this.label = '',
  });

  /// Texture formats for each color attachment. Null elements are unused slots.
  final List<GpuTextureFormat?> colorFormats;

  /// Depth/stencil format, or null if no depth/stencil is used.
  final GpuTextureFormat? depthStencilFormat;

  /// Number of samples per pixel.
  final int sampleCount;

  /// Whether the depth attachment is read-only.
  final bool depthReadOnly;

  /// Whether the stencil attachment is read-only.
  final bool stencilReadOnly;

  /// Debug label.
  final String label;
}

/// Timestamp writes for a render pass.
///
/// See [WebGPU spec: GPURenderPassTimestampWrites](https://www.w3.org/TR/webgpu/#dictdef-gpurenderpasstimestampwrites).
class GpuRenderPassTimestampWrites {
  /// Creates render pass timestamp writes.
  const GpuRenderPassTimestampWrites({
    required this.querySet,
    this.beginningOfPassWriteIndex,
    this.endOfPassWriteIndex,
  });

  /// The query set to write timestamps into.
  final GpuQuerySet querySet;

  /// Query index to write the beginning-of-pass timestamp, or null.
  final int? beginningOfPassWriteIndex;

  /// Query index to write the end-of-pass timestamp, or null.
  final int? endOfPassWriteIndex;
}

/// Timestamp writes for a compute pass.
///
/// See [WebGPU spec: GPUComputePassTimestampWrites](https://www.w3.org/TR/webgpu/#dictdef-gpucomputepasstimestampwrites).
class GpuComputePassTimestampWrites {
  /// Creates compute pass timestamp writes.
  const GpuComputePassTimestampWrites({
    required this.querySet,
    this.beginningOfPassWriteIndex,
    this.endOfPassWriteIndex,
  });

  /// The query set to write timestamps into.
  final GpuQuerySet querySet;

  /// Query index to write the beginning-of-pass timestamp, or null.
  final int? beginningOfPassWriteIndex;

  /// Query index to write the end-of-pass timestamp, or null.
  final int? endOfPassWriteIndex;
}
