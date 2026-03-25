import 'dart:js_interop';
import 'dart:typed_data';

import 'package:gpuweb/gpuweb.dart';
import 'package:meta/meta.dart';

import 'convert.dart';
import 'js/webgpu.dart';
import 'resources.dart';

class WebGpuBindGroupLayout implements GpuBindGroupLayout {
  WebGpuBindGroupLayout(this._js);

  final JsGpuBindGroupLayout _js;

  @internal
  JsGpuBindGroupLayout get jsLayout => _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;
}

class WebGpuBindGroup implements GpuBindGroup {
  WebGpuBindGroup(this._js);

  final JsGpuBindGroup _js;

  @internal
  JsGpuBindGroup get jsBindGroup => _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;
}

class WebGpuPipelineLayout implements GpuPipelineLayout {
  WebGpuPipelineLayout(this._js);

  final JsGpuPipelineLayout _js;

  @internal
  JsGpuPipelineLayout get jsLayout => _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;
}

class WebGpuRenderPipeline implements GpuRenderPipeline {
  WebGpuRenderPipeline(this._js);

  final JsGpuRenderPipeline _js;

  @internal
  JsGpuRenderPipeline get jsPipeline => _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;

  @override
  WebGpuBindGroupLayout getBindGroupLayout(int index) =>
      WebGpuBindGroupLayout(_js.getBindGroupLayout(index));
}

class WebGpuComputePipeline implements GpuComputePipeline {
  WebGpuComputePipeline(this._js);

  final JsGpuComputePipeline _js;

  @internal
  JsGpuComputePipeline get jsPipeline => _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;

  @override
  WebGpuBindGroupLayout getBindGroupLayout(int index) =>
      WebGpuBindGroupLayout(_js.getBindGroupLayout(index));
}

class WebGpuRenderBundle implements GpuRenderBundle {
  WebGpuRenderBundle(this._js);

  final JsGpuRenderBundle _js;

  @internal
  JsGpuRenderBundle get jsBundle => _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;
}

class WebGpuRenderBundleEncoder implements GpuRenderBundleEncoder {
  WebGpuRenderBundleEncoder(this._js);

  final JsGpuRenderBundleEncoder _js;

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
  void insertDebugMarker(String label) => _js.insertDebugMarker(label);
  @override
  void pushDebugGroup(String label) => _js.pushDebugGroup(label);
  @override
  void popDebugGroup() => _js.popDebugGroup();

  @override
  WebGpuRenderBundle finish({String label = ''}) {
    final desc = label.isEmpty
        ? null
        : <String, Object?>{'label': label}.jsify() as JSObject;
    return WebGpuRenderBundle(_js.finish(desc));
  }
}
