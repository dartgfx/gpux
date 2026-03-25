import 'dart:js_interop';
import 'dart:typed_data';

import 'package:gpuweb/gpuweb.dart';

import 'convert.dart';
import 'js/webgpu.dart';
import 'encoder.dart';
import 'resources.dart';

/// Web implementation of [GpuQueue].
class WebGpuQueue implements GpuQueue {
  WebGpuQueue(this._js);

  final JsGpuQueue _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;

  @override
  void submit(List<GpuCommandBuffer> commandBuffers) {
    final jsArray = [
      for (final cb in commandBuffers)
        (cb as WebGpuCommandBuffer).jsCommandBuffer,
    ].toJS;
    _js.submit(jsArray);
  }

  @override
  Future<void> onSubmittedWorkDone() => _js.onSubmittedWorkDone().toDart;

  @override
  void writeBuffer(
    GpuBuffer buffer,
    Uint8List data, {
    int bufferOffset = 0,
    int dataOffset = 0,
    int? size,
  }) {
    final jsBuffer = (buffer as WebGpuBuffer).jsBuffer;
    final jsData = data.toJS;
    // Must not pass null for optional JS params — null ≠ undefined in JS.
    if (size != null) {
      _js.writeBuffer(jsBuffer, bufferOffset, jsData, dataOffset, size);
    } else if (dataOffset != 0) {
      _js.writeBuffer(jsBuffer, bufferOffset, jsData, dataOffset);
    } else {
      _js.writeBuffer(jsBuffer, bufferOffset, jsData);
    }
  }

  @override
  void writeTexture({
    required GpuTexture texture,
    required Uint8List data,
    required int bytesPerRow,
    required int width,
    int height = 1,
    int depthOrArrayLayers = 1,
    int mipLevel = 0,
    GpuTextureAspect aspect = GpuTextureAspect.all,
    int originX = 0,
    int originY = 0,
    int originZ = 0,
    int dataOffset = 0,
    int? rowsPerImage,
  }) {
    final destination =
        <String, Object?>{
              'texture': (texture as WebGpuTexture).jsTexture,
              if (mipLevel != 0) 'mipLevel': mipLevel,
              if (originX != 0 || originY != 0 || originZ != 0)
                'origin': [originX, originY, originZ],
              if (aspect != GpuTextureAspect.all)
                'aspect': textureAspectToJs(aspect),
            }.jsify()
            as JSObject;

    final dataLayout =
        <String, Object?>{
              if (dataOffset != 0) 'offset': dataOffset,
              'bytesPerRow': bytesPerRow,
              if (rowsPerImage != null) 'rowsPerImage': rowsPerImage,
            }.jsify()
            as JSObject;

    final size =
        <String, Object?>{
              'width': width,
              if (height != 1) 'height': height,
              if (depthOrArrayLayers != 1)
                'depthOrArrayLayers': depthOrArrayLayers,
            }.jsify()
            as JSObject;

    _js.writeTexture(destination, data.toJS, dataLayout, size);
  }

  /// Copy an external image source (OffscreenCanvas, ImageBitmap, etc.)
  /// directly to a GPU texture without CPU readback.
  void copyExternalImageToTexture({
    required JSObject source,
    required GpuTexture texture,
    required int width,
    int height = 1,
    int mipLevel = 0,
    bool premultipliedAlpha = true,
  }) {
    final srcObj = <String, Object?>{'source': source}.jsify() as JSObject;

    final dstObj =
        <String, Object?>{
              'texture': (texture as WebGpuTexture).jsTexture,
              if (mipLevel != 0) 'mipLevel': mipLevel,
              'premultipliedAlpha': premultipliedAlpha,
            }.jsify()
            as JSObject;

    final sizeObj =
        <String, Object?>{
              'width': width,
              if (height != 1) 'height': height,
            }.jsify()
            as JSObject;

    _js.copyExternalImageToTexture(srcObj, dstObj, sizeObj);
  }
}
