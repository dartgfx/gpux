import 'dart:js_interop';

// ---------------------------------------------------------------------------
// Global access
// ---------------------------------------------------------------------------

@JS('navigator')
external JsNavigator get jsNavigator;

extension type JsNavigator._(JSObject _) implements JSObject {
  external JsGpu? get gpu;
}

// ---------------------------------------------------------------------------
// Set-like (for GPUSupportedFeatures / WGSLLanguageFeatures)
// ---------------------------------------------------------------------------

extension type JsSetLike(JSObject _) implements JSObject {
  external bool has(String value);
}

// ---------------------------------------------------------------------------
// GPU (entry point)
// ---------------------------------------------------------------------------

extension type JsGpu._(JSObject _) implements JSObject {
  external JSPromise<JsGpuAdapter?> requestAdapter([JSObject? options]);
  external JSObject get wgslLanguageFeatures;
  external String getPreferredCanvasFormat();
}

// ---------------------------------------------------------------------------
// GPUAdapter
// ---------------------------------------------------------------------------

extension type JsGpuAdapter._(JSObject _) implements JSObject {
  external JSObject get features;
  external JsGpuSupportedLimits get limits;
  external JsGpuAdapterInfo get info;
  external JSPromise<JsGpuDevice> requestDevice([JSObject? descriptor]);
}

extension type JsGpuSupportedLimits._(JSObject _) implements JSObject {
  external int get maxTextureDimension1D;
  external int get maxTextureDimension2D;
  external int get maxTextureDimension3D;
  external int get maxTextureArrayLayers;
  external int get maxBindGroups;
  external int get maxBindGroupsPlusVertexBuffers;
  external int get maxBindingsPerBindGroup;
  external int get maxDynamicUniformBuffersPerPipelineLayout;
  external int get maxDynamicStorageBuffersPerPipelineLayout;
  external int get maxSampledTexturesPerShaderStage;
  external int get maxSamplersPerShaderStage;
  external int get maxStorageBuffersPerShaderStage;
  external int get maxStorageTexturesPerShaderStage;
  external int get maxUniformBuffersPerShaderStage;
  external int get maxUniformBufferBindingSize;
  external int get maxStorageBufferBindingSize;
  external int get minUniformBufferOffsetAlignment;
  external int get minStorageBufferOffsetAlignment;
  external int get maxVertexBuffers;
  external int get maxBufferSize;
  external int get maxVertexAttributes;
  external int get maxVertexBufferArrayStride;
  external int get maxInterStageShaderVariables;
  external int get maxColorAttachments;
  external int get maxColorAttachmentBytesPerSample;
  external int get maxComputeWorkgroupStorageSize;
  external int get maxComputeInvocationsPerWorkgroup;
  external int get maxComputeWorkgroupSizeX;
  external int get maxComputeWorkgroupSizeY;
  external int get maxComputeWorkgroupSizeZ;
  external int get maxComputeWorkgroupsPerDimension;
}

extension type JsGpuAdapterInfo._(JSObject _) implements JSObject {
  external String get vendor;
  external String get architecture;
  external String get device;
  external String get description;
  external int get subgroupMinSize;
  external int get subgroupMaxSize;
}

// ---------------------------------------------------------------------------
// GPUDevice
// ---------------------------------------------------------------------------

extension type JsGpuDevice._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
  external JSObject get features;
  external JsGpuSupportedLimits get limits;
  external JsGpuQueue get queue;
  external JsGpuAdapterInfo get adapterInfo;
  external JSPromise get lost;
  external JsGpuBuffer createBuffer(JSObject descriptor);
  external JsGpuTexture createTexture(JSObject descriptor);
  external JsGpuSampler createSampler([JSObject? descriptor]);
  external JsGpuShaderModule createShaderModule(JSObject descriptor);
  external JsGpuCommandEncoder createCommandEncoder([JSObject? descriptor]);
  external JsGpuQuerySet createQuerySet(JSObject descriptor);
  external JsGpuBindGroupLayout createBindGroupLayout(JSObject descriptor);
  external JsGpuBindGroup createBindGroup(JSObject descriptor);
  external JsGpuPipelineLayout createPipelineLayout(JSObject descriptor);
  external JsGpuComputePipeline createComputePipeline(JSObject descriptor);
  external JsGpuRenderPipeline createRenderPipeline(JSObject descriptor);
  external JSPromise<JsGpuComputePipeline> createComputePipelineAsync(
    JSObject descriptor,
  );
  external JSPromise<JsGpuRenderPipeline> createRenderPipelineAsync(
    JSObject descriptor,
  );
  external JsGpuRenderBundleEncoder createRenderBundleEncoder(
    JSObject descriptor,
  );
  external void pushErrorScope(String filter);
  external JSPromise<JSObject?> popErrorScope();
  external set onuncapturederror(JSFunction? handler);
  external void destroy();
}

// ---------------------------------------------------------------------------
// GPUQueue
// ---------------------------------------------------------------------------

extension type JsGpuQueue._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
  external void submit(JSArray commandBuffers);
  external JSPromise onSubmittedWorkDone();
  external void writeBuffer(
    JsGpuBuffer buffer,
    int bufferOffset,
    JSObject data, [
    int? dataOffset,
    int? size,
  ]);
  external void writeTexture(
    JSObject destination,
    JSObject data,
    JSObject dataLayout,
    JSObject size,
  );
  external void copyExternalImageToTexture(
    JSObject source,
    JSObject destination,
    JSObject copySize,
  );
}

// ---------------------------------------------------------------------------
// GPUBuffer
// ---------------------------------------------------------------------------

extension type JsGpuBuffer._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
  external int get size;
  external int get usage;
  external String get mapState;
  external JSPromise mapAsync(int mode, [int? offset, int? size]);
  external JSArrayBuffer getMappedRange([int? offset, int? size]);
  external void unmap();
  external void destroy();
}

// ---------------------------------------------------------------------------
// GPUTexture / GPUTextureView
// ---------------------------------------------------------------------------

extension type JsGpuTexture._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
  external int get width;
  external int get height;
  external int get depthOrArrayLayers;
  external String get dimension;
  external String get format;
  external int get usage;
  external int get mipLevelCount;
  external int get sampleCount;
  external JsGpuTextureView createView([JSObject? descriptor]);
  external void destroy();
}

extension type JsGpuTextureView._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
}

// ---------------------------------------------------------------------------
// GPUSampler
// ---------------------------------------------------------------------------

extension type JsGpuSampler._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
}

// ---------------------------------------------------------------------------
// GPUShaderModule
// ---------------------------------------------------------------------------

extension type JsGpuShaderModule._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
  external JSPromise<JsGpuCompilationInfo> getCompilationInfo();
}

extension type JsGpuCompilationInfo._(JSObject _) implements JSObject {
  external JSArray<JsGpuCompilationMessage> get messages;
}

extension type JsGpuCompilationMessage._(JSObject _) implements JSObject {
  external String get message;
  external String get type;
  external int get lineNum;
  external int get linePos;
  external int get offset;
  external int get length;
}

// ---------------------------------------------------------------------------
// GPUCommandEncoder
// ---------------------------------------------------------------------------

extension type JsGpuCommandEncoder._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
  external JsGpuRenderPassEncoder beginRenderPass(JSObject descriptor);
  external JsGpuComputePassEncoder beginComputePass([JSObject? descriptor]);
  external void copyBufferToBuffer(
    JsGpuBuffer source,
    int sourceOffset,
    JsGpuBuffer destination,
    int destinationOffset,
    int size,
  );
  external void clearBuffer(JsGpuBuffer buffer, [int? offset, int? size]);
  external void copyTextureToBuffer(
    JSObject source,
    JSObject destination,
    JSObject copySize,
  );
  external void copyBufferToTexture(
    JSObject source,
    JSObject destination,
    JSObject copySize,
  );
  external void copyTextureToTexture(
    JSObject source,
    JSObject destination,
    JSObject copySize,
  );
  external void resolveQuerySet(
    JsGpuQuerySet querySet,
    int firstQuery,
    int queryCount,
    JsGpuBuffer destination,
    int destinationOffset,
  );
  external void insertDebugMarker(String markerLabel);
  external void pushDebugGroup(String groupLabel);
  external void popDebugGroup();
  external JsGpuCommandBuffer finish([JSObject? descriptor]);
}

// ---------------------------------------------------------------------------
// GPURenderPassEncoder
// ---------------------------------------------------------------------------

extension type JsGpuRenderPassEncoder._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
  external void setPipeline(JsGpuRenderPipeline pipeline);
  external void setBindGroup(
    int index,
    JsGpuBindGroup? bindGroup, [
    JSObject? dynamicOffsets,
  ]);
  external void setVertexBuffer(
    int slot,
    JsGpuBuffer? buffer, [
    int? offset,
    int? size,
  ]);
  external void setIndexBuffer(
    JsGpuBuffer buffer,
    String indexFormat, [
    int? offset,
    int? size,
  ]);
  external void draw(
    int vertexCount, [
    int? instanceCount,
    int? firstVertex,
    int? firstInstance,
  ]);
  external void drawIndexed(
    int indexCount, [
    int? instanceCount,
    int? firstIndex,
    int? baseVertex,
    int? firstInstance,
  ]);
  external void drawIndirect(JsGpuBuffer indirectBuffer, int indirectOffset);
  external void drawIndexedIndirect(
    JsGpuBuffer indirectBuffer,
    int indirectOffset,
  );
  external void beginOcclusionQuery(int queryIndex);
  external void endOcclusionQuery();
  external void setViewport(
    double x,
    double y,
    double width,
    double height,
    double minDepth,
    double maxDepth,
  );
  external void setScissorRect(int x, int y, int width, int height);
  external void setBlendConstant(JSObject color);
  external void setStencilReference(int reference);
  external void insertDebugMarker(String markerLabel);
  external void pushDebugGroup(String groupLabel);
  external void popDebugGroup();
  external void executeBundles(JSArray bundles);
  external void end();
}

// ---------------------------------------------------------------------------
// GPUComputePassEncoder
// ---------------------------------------------------------------------------

extension type JsGpuComputePassEncoder._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
  external void setPipeline(JsGpuComputePipeline pipeline);
  external void setBindGroup(
    int index,
    JsGpuBindGroup? bindGroup, [
    JSObject? dynamicOffsets,
  ]);
  external void dispatchWorkgroups(int x, [int? y, int? z]);
  external void dispatchWorkgroupsIndirect(
    JsGpuBuffer indirectBuffer,
    int indirectOffset,
  );
  external void insertDebugMarker(String markerLabel);
  external void pushDebugGroup(String groupLabel);
  external void popDebugGroup();
  external void end();
}

// ---------------------------------------------------------------------------
// GPUCommandBuffer
// ---------------------------------------------------------------------------

extension type JsGpuCommandBuffer._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
}

// ---------------------------------------------------------------------------
// Pipelines
// ---------------------------------------------------------------------------

extension type JsGpuRenderPipeline._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
  external JsGpuBindGroupLayout getBindGroupLayout(int index);
}

extension type JsGpuComputePipeline._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
  external JsGpuBindGroupLayout getBindGroupLayout(int index);
}

extension type JsGpuPipelineLayout._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
}

// ---------------------------------------------------------------------------
// Bind groups
// ---------------------------------------------------------------------------

extension type JsGpuBindGroupLayout._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
}

extension type JsGpuBindGroup._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
}

// ---------------------------------------------------------------------------
// GPURenderBundle / GPURenderBundleEncoder
// ---------------------------------------------------------------------------

extension type JsGpuRenderBundle._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
}

extension type JsGpuRenderBundleEncoder._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
  external void setPipeline(JsGpuRenderPipeline pipeline);
  external void setBindGroup(
    int index,
    JsGpuBindGroup? bindGroup, [
    JSObject? dynamicOffsets,
  ]);
  external void setVertexBuffer(
    int slot,
    JsGpuBuffer? buffer, [
    int? offset,
    int? size,
  ]);
  external void setIndexBuffer(
    JsGpuBuffer buffer,
    String indexFormat, [
    int? offset,
    int? size,
  ]);
  external void draw(
    int vertexCount, [
    int? instanceCount,
    int? firstVertex,
    int? firstInstance,
  ]);
  external void drawIndexed(
    int indexCount, [
    int? instanceCount,
    int? firstIndex,
    int? baseVertex,
    int? firstInstance,
  ]);
  external void drawIndirect(JsGpuBuffer indirectBuffer, int indirectOffset);
  external void drawIndexedIndirect(
    JsGpuBuffer indirectBuffer,
    int indirectOffset,
  );
  external void insertDebugMarker(String markerLabel);
  external void pushDebugGroup(String groupLabel);
  external void popDebugGroup();
  external JsGpuRenderBundle finish([JSObject? descriptor]);
}

// ---------------------------------------------------------------------------
// GPUQuerySet
// ---------------------------------------------------------------------------

extension type JsGpuQuerySet._(JSObject _) implements JSObject {
  external String get label;
  external set label(String value);
  external String get type;
  external int get count;
  external void destroy();
}

// ---------------------------------------------------------------------------
// GPUCanvasContext
// ---------------------------------------------------------------------------

extension type JsGpuCanvasContext(JSObject _) implements JSObject {
  external JSObject get canvas;
  external void configure(JSObject configuration);
  external void unconfigure();
  external JsGpuTexture getCurrentTexture();
}
