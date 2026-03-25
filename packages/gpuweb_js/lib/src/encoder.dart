import 'dart:js_interop';
import 'dart:typed_data';

import 'package:gpuweb/gpuweb.dart';
import 'package:meta/meta.dart';

import 'convert.dart';
import 'js/webgpu.dart';
import 'pipeline.dart';
import 'resources.dart';

class WebGpuCommandEncoder implements GpuCommandEncoder {
  WebGpuCommandEncoder(this._js);

  final JsGpuCommandEncoder _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;

  @override
  WebGpuRenderPassEncoder beginRenderPass({
    required List<GpuColorAttachment> colorAttachments,
    GpuDepthStencilAttachment? depthStencilAttachment,
    GpuQuerySet? occlusionQuerySet,
    GpuRenderPassTimestampWrites? timestampWrites,
    int maxDrawCount = 50000000,
    String label = '',
  }) {
    final jsColors = <Map<String, Object?>?>[];
    for (final ca in colorAttachments) {
      jsColors.add(<String, Object?>{
        'view': (ca.view as WebGpuTextureView).jsView,
        if (ca.resolveTarget != null)
          'resolveTarget': (ca.resolveTarget as WebGpuTextureView).jsView,
        'loadOp': loadOpToJs(ca.loadOp),
        'storeOp': storeOpToJs(ca.storeOp),
        if (ca.clearValue != null)
          'clearValue': [
            ca.clearValue!.r,
            ca.clearValue!.g,
            ca.clearValue!.b,
            ca.clearValue!.a,
          ],
        if (ca.depthSlice != null) 'depthSlice': ca.depthSlice,
      });
    }

    final desc = <String, Object?>{
      'colorAttachments': jsColors,
      if (label.isNotEmpty) 'label': label,
      if (maxDrawCount != 50000000) 'maxDrawCount': maxDrawCount,
    };

    if (depthStencilAttachment != null) {
      final ds = depthStencilAttachment;
      desc['depthStencilAttachment'] = <String, Object?>{
        'view': (ds.view as WebGpuTextureView).jsView,
        if (ds.depthLoadOp != null) 'depthLoadOp': loadOpToJs(ds.depthLoadOp!),
        if (ds.depthStoreOp != null)
          'depthStoreOp': storeOpToJs(ds.depthStoreOp!),
        if (ds.depthClearValue != null) 'depthClearValue': ds.depthClearValue,
        if (ds.depthReadOnly) 'depthReadOnly': true,
        if (ds.stencilLoadOp != null)
          'stencilLoadOp': loadOpToJs(ds.stencilLoadOp!),
        if (ds.stencilStoreOp != null)
          'stencilStoreOp': storeOpToJs(ds.stencilStoreOp!),
        if (ds.stencilClearValue != 0)
          'stencilClearValue': ds.stencilClearValue,
        if (ds.stencilReadOnly) 'stencilReadOnly': true,
      };
    }

    if (occlusionQuerySet != null) {
      desc['occlusionQuerySet'] =
          (occlusionQuerySet as WebGpuQuerySet).jsQuerySet;
    }

    if (timestampWrites != null) {
      desc['timestampWrites'] = <String, Object?>{
        'querySet': (timestampWrites.querySet as WebGpuQuerySet).jsQuerySet,
        if (timestampWrites.beginningOfPassWriteIndex != null)
          'beginningOfPassWriteIndex':
              timestampWrites.beginningOfPassWriteIndex,
        if (timestampWrites.endOfPassWriteIndex != null)
          'endOfPassWriteIndex': timestampWrites.endOfPassWriteIndex,
      };
    }

    return WebGpuRenderPassEncoder(
      _js.beginRenderPass(desc.jsify() as JSObject),
    );
  }

  @override
  WebGpuComputePassEncoder beginComputePass({
    GpuComputePassTimestampWrites? timestampWrites,
    String label = '',
  }) {
    JSObject? desc;
    if (timestampWrites != null || label.isNotEmpty) {
      final d = <String, Object?>{if (label.isNotEmpty) 'label': label};
      if (timestampWrites != null) {
        d['timestampWrites'] = <String, Object?>{
          'querySet': (timestampWrites.querySet as WebGpuQuerySet).jsQuerySet,
          if (timestampWrites.beginningOfPassWriteIndex != null)
            'beginningOfPassWriteIndex':
                timestampWrites.beginningOfPassWriteIndex,
          if (timestampWrites.endOfPassWriteIndex != null)
            'endOfPassWriteIndex': timestampWrites.endOfPassWriteIndex,
        };
      }
      desc = d.jsify() as JSObject;
    }
    return WebGpuComputePassEncoder(_js.beginComputePass(desc));
  }

  @override
  void copyBufferToBuffer({
    required GpuBuffer source,
    int sourceOffset = 0,
    required GpuBuffer destination,
    int destinationOffset = 0,
    required int size,
  }) {
    _js.copyBufferToBuffer(
      (source as WebGpuBuffer).jsBuffer,
      sourceOffset,
      (destination as WebGpuBuffer).jsBuffer,
      destinationOffset,
      size,
    );
  }

  @override
  void clearBuffer(GpuBuffer buffer, {int offset = 0, int? size}) {
    final jsBuffer = (buffer as WebGpuBuffer).jsBuffer;
    if (size != null) {
      _js.clearBuffer(jsBuffer, offset, size);
    } else if (offset != 0) {
      _js.clearBuffer(jsBuffer, offset);
    } else {
      _js.clearBuffer(jsBuffer);
    }
  }

  @override
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
  }) {
    final src =
        <String, Object?>{
              'texture': (source as WebGpuTexture).jsTexture,
              if (mipLevel != 0) 'mipLevel': mipLevel,
              if (originX != 0 || originY != 0 || originZ != 0)
                'origin': [originX, originY, originZ],
            }.jsify()
            as JSObject;
    final dst =
        <String, Object?>{
              'buffer': (destination as WebGpuBuffer).jsBuffer,
              'bytesPerRow': bytesPerRow,
              if (rowsPerImage != null) 'rowsPerImage': rowsPerImage,
            }.jsify()
            as JSObject;
    final size =
        <String, Object?>{
              'width': width,
              'height': height,
              if (depth != 1) 'depthOrArrayLayers': depth,
            }.jsify()
            as JSObject;
    _js.copyTextureToBuffer(src, dst, size);
  }

  @override
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
  }) {
    final src =
        <String, Object?>{
              'buffer': (source as WebGpuBuffer).jsBuffer,
              'bytesPerRow': bytesPerRow,
              if (rowsPerImage != null) 'rowsPerImage': rowsPerImage,
            }.jsify()
            as JSObject;
    final dst =
        <String, Object?>{
              'texture': (destination as WebGpuTexture).jsTexture,
              if (mipLevel != 0) 'mipLevel': mipLevel,
              if (originX != 0 || originY != 0 || originZ != 0)
                'origin': [originX, originY, originZ],
            }.jsify()
            as JSObject;
    final size =
        <String, Object?>{
              'width': width,
              'height': height,
              if (depth != 1) 'depthOrArrayLayers': depth,
            }.jsify()
            as JSObject;
    _js.copyBufferToTexture(src, dst, size);
  }

  @override
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
  }) {
    final src =
        <String, Object?>{
              'texture': (source as WebGpuTexture).jsTexture,
              if (srcMipLevel != 0) 'mipLevel': srcMipLevel,
              if (srcOriginX != 0 || srcOriginY != 0 || srcOriginZ != 0)
                'origin': [srcOriginX, srcOriginY, srcOriginZ],
            }.jsify()
            as JSObject;
    final dst =
        <String, Object?>{
              'texture': (destination as WebGpuTexture).jsTexture,
              if (dstMipLevel != 0) 'mipLevel': dstMipLevel,
              if (dstOriginX != 0 || dstOriginY != 0 || dstOriginZ != 0)
                'origin': [dstOriginX, dstOriginY, dstOriginZ],
            }.jsify()
            as JSObject;
    final size =
        <String, Object?>{
              'width': width,
              'height': height,
              if (depth != 1) 'depthOrArrayLayers': depth,
            }.jsify()
            as JSObject;
    _js.copyTextureToTexture(src, dst, size);
  }

  @override
  void resolveQuerySet(
    GpuQuerySet querySet, {
    required int firstQuery,
    required int queryCount,
    required GpuBuffer destination,
    int destinationOffset = 0,
  }) {
    _js.resolveQuerySet(
      (querySet as WebGpuQuerySet).jsQuerySet,
      firstQuery,
      queryCount,
      (destination as WebGpuBuffer).jsBuffer,
      destinationOffset,
    );
  }

  @override
  void insertDebugMarker(String label) => _js.insertDebugMarker(label);
  @override
  void pushDebugGroup(String label) => _js.pushDebugGroup(label);
  @override
  void popDebugGroup() => _js.popDebugGroup();

  @override
  WebGpuCommandBuffer finish({String label = ''}) {
    final desc = label.isEmpty
        ? null
        : <String, Object?>{'label': label}.jsify() as JSObject;
    return WebGpuCommandBuffer(_js.finish(desc));
  }
}

class WebGpuCommandBuffer implements GpuCommandBuffer {
  WebGpuCommandBuffer(this._js);

  final JsGpuCommandBuffer _js;

  @internal
  JsGpuCommandBuffer get jsCommandBuffer => _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;
}

class WebGpuRenderPassEncoder implements GpuRenderPassEncoder {
  WebGpuRenderPassEncoder(this._js);

  final JsGpuRenderPassEncoder _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;

  @override
  void setPipeline(GpuRenderPipeline pipeline) =>
      _js.setPipeline((pipeline as WebGpuRenderPipeline).jsPipeline);

  @override
  void setBindGroup(
    int index,
    GpuBindGroup bindGroup, {
    List<int>? dynamicOffsets,
  }) {
    final bg = (bindGroup as WebGpuBindGroup).jsBindGroup;
    if (dynamicOffsets != null) {
      _js.setBindGroup(
        index,
        bg,
        Uint32List.fromList(dynamicOffsets).toJS as JSObject,
      );
    } else {
      _js.setBindGroup(index, bg);
    }
  }

  @override
  void setVertexBuffer(
    int slot,
    GpuBuffer? buffer, {
    int offset = 0,
    int? size,
  }) {
    final jsBuffer = buffer == null ? null : (buffer as WebGpuBuffer).jsBuffer;
    if (size != null) {
      _js.setVertexBuffer(slot, jsBuffer, offset, size);
    } else {
      _js.setVertexBuffer(slot, jsBuffer, offset);
    }
  }

  @override
  void setIndexBuffer(
    GpuBuffer buffer,
    GpuIndexFormat format, {
    int offset = 0,
    int? size,
  }) {
    final jsBuffer = (buffer as WebGpuBuffer).jsBuffer;
    final jsFormat = indexFormatToJs(format);
    if (size != null) {
      _js.setIndexBuffer(jsBuffer, jsFormat, offset, size);
    } else {
      _js.setIndexBuffer(jsBuffer, jsFormat, offset);
    }
  }

  @override
  void draw({
    required int vertexCount,
    int instanceCount = 1,
    int firstVertex = 0,
    int firstInstance = 0,
  }) => _js.draw(vertexCount, instanceCount, firstVertex, firstInstance);

  @override
  void drawIndexed({
    required int indexCount,
    int instanceCount = 1,
    int firstIndex = 0,
    int baseVertex = 0,
    int firstInstance = 0,
  }) => _js.drawIndexed(
    indexCount,
    instanceCount,
    firstIndex,
    baseVertex,
    firstInstance,
  );

  @override
  void drawIndirect(GpuBuffer indirectBuffer, {int indirectOffset = 0}) => _js
      .drawIndirect((indirectBuffer as WebGpuBuffer).jsBuffer, indirectOffset);

  @override
  void drawIndexedIndirect(
    GpuBuffer indirectBuffer, {
    int indirectOffset = 0,
  }) => _js.drawIndexedIndirect(
    (indirectBuffer as WebGpuBuffer).jsBuffer,
    indirectOffset,
  );

  @override
  void beginOcclusionQuery(int queryIndex) =>
      _js.beginOcclusionQuery(queryIndex);

  @override
  void endOcclusionQuery() => _js.endOcclusionQuery();

  @override
  void setViewport(
    double x,
    double y,
    double width,
    double height, {
    double minDepth = 0.0,
    double maxDepth = 1.0,
  }) => _js.setViewport(x, y, width, height, minDepth, maxDepth);

  @override
  void setScissorRect(int x, int y, int width, int height) =>
      _js.setScissorRect(x, y, width, height);

  @override
  void setBlendConstant(GpuColor color) {
    final jsColor =
        <String, Object?>{
              'r': color.r,
              'g': color.g,
              'b': color.b,
              'a': color.a,
            }.jsify()
            as JSObject;
    _js.setBlendConstant(jsColor);
  }

  @override
  void setStencilReference(int reference) => _js.setStencilReference(reference);

  @override
  void insertDebugMarker(String label) => _js.insertDebugMarker(label);
  @override
  void pushDebugGroup(String label) => _js.pushDebugGroup(label);
  @override
  void popDebugGroup() => _js.popDebugGroup();

  @override
  void executeBundles(List<GpuRenderBundle> bundles) {
    final jsArray = [
      for (final b in bundles) (b as WebGpuRenderBundle).jsBundle,
    ].toJS;
    _js.executeBundles(jsArray);
  }

  @override
  void end() => _js.end();
}

// ===========================================================================
// Compute pass encoder
// ===========================================================================

class WebGpuComputePassEncoder implements GpuComputePassEncoder {
  WebGpuComputePassEncoder(this._js);

  final JsGpuComputePassEncoder _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;

  @override
  void setPipeline(GpuComputePipeline pipeline) =>
      _js.setPipeline((pipeline as WebGpuComputePipeline).jsPipeline);

  @override
  void setBindGroup(
    int index,
    GpuBindGroup bindGroup, {
    List<int>? dynamicOffsets,
  }) {
    final bg = (bindGroup as WebGpuBindGroup).jsBindGroup;
    if (dynamicOffsets != null) {
      _js.setBindGroup(
        index,
        bg,
        Uint32List.fromList(dynamicOffsets).toJS as JSObject,
      );
    } else {
      _js.setBindGroup(index, bg);
    }
  }

  @override
  void dispatchWorkgroups(int x, [int y = 1, int z = 1]) =>
      _js.dispatchWorkgroups(x, y, z);

  @override
  void dispatchWorkgroupsIndirect(GpuBuffer buffer, {int offset = 0}) =>
      _js.dispatchWorkgroupsIndirect((buffer as WebGpuBuffer).jsBuffer, offset);

  @override
  void insertDebugMarker(String label) => _js.insertDebugMarker(label);
  @override
  void pushDebugGroup(String label) => _js.pushDebugGroup(label);
  @override
  void popDebugGroup() => _js.popDebugGroup();

  @override
  void end() => _js.end();
}
