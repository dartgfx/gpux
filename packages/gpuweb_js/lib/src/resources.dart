import 'dart:js_interop';
import 'dart:typed_data';

import 'package:gpuweb/gpuweb.dart';
import 'package:meta/meta.dart';

import 'convert.dart';
import 'js/webgpu.dart';

class WebGpuBuffer implements GpuBuffer {
  WebGpuBuffer(this._js);

  final JsGpuBuffer _js;

  @internal
  JsGpuBuffer get jsBuffer => _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;

  @override
  int get size => _js.size;

  @override
  GpuBufferUsageFlags get usage => GpuBufferUsageFlags(_js.usage);

  @override
  GpuBufferMapState get mapState => bufferMapStateFromJs(_js.mapState);

  @override
  Future<void> mapAsync(GpuMapModeFlags mode, {int offset = 0, int? size}) {
    if (size != null) return _js.mapAsync(mode as int, offset, size).toDart;
    if (offset != 0) return _js.mapAsync(mode as int, offset).toDart;
    return _js.mapAsync(mode as int).toDart;
  }

  @override
  ByteBuffer getMappedRange({int offset = 0, int? size}) {
    if (size != null) return _js.getMappedRange(offset, size).toDart;
    if (offset != 0) return _js.getMappedRange(offset).toDart;
    return _js.getMappedRange().toDart;
  }

  @override
  void unmap() => _js.unmap();

  @override
  void destroy() => _js.destroy();
}

class WebGpuTexture implements GpuTexture {
  WebGpuTexture(this._js);

  final JsGpuTexture _js;

  @internal
  JsGpuTexture get jsTexture => _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;

  @override
  int get width => _js.width;
  @override
  int get height => _js.height;
  @override
  int get depthOrArrayLayers => _js.depthOrArrayLayers;
  @override
  GpuTextureDimension get dimension => textureDimensionFromJs(_js.dimension);
  @override
  GpuTextureFormat get format => textureFormatFromJs(_js.format);
  @override
  int get usage => _js.usage;
  @override
  int get mipLevelCount => _js.mipLevelCount;
  @override
  int get sampleCount => _js.sampleCount;

  @override
  GpuTextureViewDimension get textureBindingViewDimension {
    // Derive from dimension (browser doesn't expose this directly).
    return switch (dimension) {
      GpuTextureDimension.d1 => GpuTextureViewDimension.d1,
      GpuTextureDimension.d2 =>
        depthOrArrayLayers > 1
            ? GpuTextureViewDimension.d2Array
            : GpuTextureViewDimension.d2,
      GpuTextureDimension.d3 => GpuTextureViewDimension.d3,
    };
  }

  @override
  WebGpuTextureView createView({
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
  }) {
    final desc = <String, Object?>{
      if (format != null) 'format': textureFormatToJs(format),
      if (dimension != null) 'dimension': textureViewDimensionToJs(dimension),
      if (baseMipLevel != 0) 'baseMipLevel': baseMipLevel,
      if (mipLevelCount != null) 'mipLevelCount': mipLevelCount,
      if (baseArrayLayer != 0) 'baseArrayLayer': baseArrayLayer,
      if (arrayLayerCount != null) 'arrayLayerCount': arrayLayerCount,
      if (aspect != GpuTextureAspect.all) 'aspect': textureAspectToJs(aspect),
      if (label.isNotEmpty) 'label': label,
    };
    final jsDesc = desc.isEmpty ? null : desc.jsify() as JSObject;
    return WebGpuTextureView(_js.createView(jsDesc));
  }

  @override
  void destroy() => _js.destroy();
}

class WebGpuTextureView implements GpuTextureView {
  WebGpuTextureView(this._js);

  final JsGpuTextureView _js;

  @internal
  JsGpuTextureView get jsView => _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;
}

class WebGpuSampler implements GpuSampler {
  WebGpuSampler(this._js);

  final JsGpuSampler _js;

  @internal
  JsGpuSampler get jsSampler => _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;
}

class WebGpuShaderModule implements GpuShaderModule {
  WebGpuShaderModule(this._js);

  final JsGpuShaderModule _js;

  @internal
  JsGpuShaderModule get jsModule => _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;

  @override
  Future<List<GpuCompilationMessage>> getCompilationInfo() async {
    final info = await _js.getCompilationInfo().toDart;
    final messages = info.messages.toDart;
    return [
      for (final m in messages)
        GpuCompilationMessage(
          message: m.message,
          type: compilationMessageTypeFromJs(m.type),
          lineNum: m.lineNum,
          linePos: m.linePos,
          offset: m.offset,
          length: m.length,
        ),
    ];
  }
}

class WebGpuQuerySet implements GpuQuerySet {
  WebGpuQuerySet(this._js);

  final JsGpuQuerySet _js;

  @internal
  JsGpuQuerySet get jsQuerySet => _js;

  @override
  String get label => _js.label;
  @override
  set label(String value) => _js.label = value;

  @override
  GpuQueryType get type => queryTypeFromJs(_js.type);

  @override
  int get count => _js.count;

  @override
  void destroy() => _js.destroy();
}
