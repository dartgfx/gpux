import 'dart:async';
import 'dart:js_interop';

import 'package:gpuweb/gpuweb.dart';
import 'package:meta/meta.dart';

import 'convert.dart';
import 'js/webgpu.dart';
import 'encoder.dart';
import 'pipeline.dart';
import 'queue.dart';
import 'resources.dart';

/// Web implementation of [GpuDevice].
class WebGpuDevice implements GpuDevice {
  WebGpuDevice(this._js) {
    _js.onuncapturederror = _onUncapturedError.toJS;
  }

  final JsGpuDevice _js;

  final _uncapturedErrorController = StreamController<GpuError>.broadcast();

  void _onUncapturedError(JSObject event) {
    final error = _JsGpuUncapturedErrorEvent(event).error;
    final message = error.message;
    final type = error.constructor.name;
    final gpuError = switch (type) {
      'GPUOutOfMemoryError' => GpuOutOfMemoryError(message),
      'GPUInternalError' => GpuInternalError(message),
      _ => GpuValidationError(message),
    };
    _uncapturedErrorController.add(gpuError);
  }

  @internal
  JsGpuDevice get jsDevice => _js;

  @override
  Set<GpuFeatureName> get features {
    final setLike = JsSetLike(_js.features);
    final result = <GpuFeatureName>{};
    for (final f in GpuFeatureName.values) {
      if (setLike.has(featureNameToJs(f))) result.add(f);
    }
    return result;
  }

  @override
  GpuLimits get limits {
    final l = _js.limits;
    return GpuLimits(
      maxTextureDimension1d: l.maxTextureDimension1D,
      maxTextureDimension2d: l.maxTextureDimension2D,
      maxTextureDimension3d: l.maxTextureDimension3D,
      maxTextureArrayLayers: l.maxTextureArrayLayers,
      maxBindGroups: l.maxBindGroups,
      maxBindGroupsPlusVertexBuffers: l.maxBindGroupsPlusVertexBuffers,
      maxBindingsPerBindGroup: l.maxBindingsPerBindGroup,
      maxDynamicUniformBuffersPerPipelineLayout:
          l.maxDynamicUniformBuffersPerPipelineLayout,
      maxDynamicStorageBuffersPerPipelineLayout:
          l.maxDynamicStorageBuffersPerPipelineLayout,
      maxSampledTexturesPerShaderStage: l.maxSampledTexturesPerShaderStage,
      maxSamplersPerShaderStage: l.maxSamplersPerShaderStage,
      maxStorageBuffersPerShaderStage: l.maxStorageBuffersPerShaderStage,
      maxStorageTexturesPerShaderStage: l.maxStorageTexturesPerShaderStage,
      maxUniformBuffersPerShaderStage: l.maxUniformBuffersPerShaderStage,
      maxUniformBufferBindingSize: l.maxUniformBufferBindingSize,
      maxStorageBufferBindingSize: l.maxStorageBufferBindingSize,
      minUniformBufferOffsetAlignment: l.minUniformBufferOffsetAlignment,
      minStorageBufferOffsetAlignment: l.minStorageBufferOffsetAlignment,
      maxVertexBuffers: l.maxVertexBuffers,
      maxBufferSize: l.maxBufferSize,
      maxVertexAttributes: l.maxVertexAttributes,
      maxVertexBufferArrayStride: l.maxVertexBufferArrayStride,
      maxInterStageShaderVariables: l.maxInterStageShaderVariables,
      maxColorAttachments: l.maxColorAttachments,
      maxColorAttachmentBytesPerSample: l.maxColorAttachmentBytesPerSample,
      maxComputeWorkgroupStorageSize: l.maxComputeWorkgroupStorageSize,
      maxComputeInvocationsPerWorkgroup: l.maxComputeInvocationsPerWorkgroup,
      maxComputeWorkgroupSizeX: l.maxComputeWorkgroupSizeX,
      maxComputeWorkgroupSizeY: l.maxComputeWorkgroupSizeY,
      maxComputeWorkgroupSizeZ: l.maxComputeWorkgroupSizeZ,
      maxComputeWorkgroupsPerDimension: l.maxComputeWorkgroupsPerDimension,
    );
  }

  @override
  GpuAdapterInfo get adapterInfo {
    final i = _js.adapterInfo;
    return GpuAdapterInfo(
      vendor: i.vendor,
      architecture: i.architecture,
      device: i.device,
      description: i.description,
      subgroupMinSize: i.subgroupMinSize,
      subgroupMaxSize: i.subgroupMaxSize,
    );
  }

  @override
  WebGpuQueue get queue => WebGpuQueue(_js.queue);

  @override
  WebGpuBuffer createBuffer({
    required int size,
    required GpuBufferUsageFlags usage,
    bool mappedAtCreation = false,
    String label = '',
  }) {
    final desc =
        <String, Object?>{
              'size': size,
              'usage': usage as int,
              if (mappedAtCreation) 'mappedAtCreation': true,
              if (label.isNotEmpty) 'label': label,
            }.jsify()
            as JSObject;
    return WebGpuBuffer(_js.createBuffer(desc));
  }

  @override
  WebGpuTexture createTexture({
    required int width,
    int height = 1,
    int depthOrArrayLayers = 1,
    int mipLevelCount = 1,
    int sampleCount = 1,
    GpuTextureDimension dimension = GpuTextureDimension.d2,
    required GpuTextureFormat format,
    required GpuTextureUsageFlags usage,
    List<GpuTextureFormat> viewFormats = const [],
    GpuTextureViewDimension? textureBindingViewDimension,
    String label = '',
  }) {
    final size = <String, Object?>{
      'width': width,
      if (height != 1) 'height': height,
      if (depthOrArrayLayers != 1) 'depthOrArrayLayers': depthOrArrayLayers,
    };
    final desc =
        <String, Object?>{
              'size': size,
              'format': textureFormatToJs(format),
              'usage': usage as int,
              if (mipLevelCount != 1) 'mipLevelCount': mipLevelCount,
              if (sampleCount != 1) 'sampleCount': sampleCount,
              if (dimension != GpuTextureDimension.d2)
                'dimension': textureDimensionToJs(dimension),
              if (viewFormats.isNotEmpty)
                'viewFormats': [
                  for (final f in viewFormats) textureFormatToJs(f),
                ],
              if (label.isNotEmpty) 'label': label,
            }.jsify()
            as JSObject;
    return WebGpuTexture(_js.createTexture(desc));
  }

  @override
  WebGpuSampler createSampler({
    GpuAddressMode addressModeU = GpuAddressMode.clampToEdge,
    GpuAddressMode addressModeV = GpuAddressMode.clampToEdge,
    GpuAddressMode addressModeW = GpuAddressMode.clampToEdge,
    GpuFilterMode magFilter = GpuFilterMode.nearest,
    GpuFilterMode minFilter = GpuFilterMode.nearest,
    GpuMipmapFilterMode mipmapFilter = GpuMipmapFilterMode.nearest,
    double lodMinClamp = 0.0,
    double lodMaxClamp = 32.0,
    int maxAnisotropy = 1,
    GpuCompareFunction? compare,
    String label = '',
  }) {
    final desc =
        <String, Object?>{
              'addressModeU': addressModeToJs(addressModeU),
              'addressModeV': addressModeToJs(addressModeV),
              'addressModeW': addressModeToJs(addressModeW),
              'magFilter': filterModeToJs(magFilter),
              'minFilter': filterModeToJs(minFilter),
              'mipmapFilter': mipmapFilterModeToJs(mipmapFilter),
              'lodMinClamp': lodMinClamp,
              'lodMaxClamp': lodMaxClamp,
              'maxAnisotropy': maxAnisotropy,
              if (compare != null) 'compare': compareFunctionToJs(compare),
              if (label.isNotEmpty) 'label': label,
            }.jsify()
            as JSObject;
    return WebGpuSampler(_js.createSampler(desc));
  }

  @override
  WebGpuShaderModule createShaderModule(
    String wgslSource, {
    String label = '',
  }) {
    final desc =
        <String, Object?>{
              'code': wgslSource,
              if (label.isNotEmpty) 'label': label,
            }.jsify()
            as JSObject;
    return WebGpuShaderModule(_js.createShaderModule(desc));
  }

  @override
  WebGpuCommandEncoder createCommandEncoder({String label = ''}) {
    final desc = label.isEmpty
        ? null
        : <String, Object?>{'label': label}.jsify() as JSObject;
    return WebGpuCommandEncoder(_js.createCommandEncoder(desc));
  }

  @override
  WebGpuQuerySet createQuerySet({
    required GpuQueryType type,
    required int count,
    String label = '',
  }) {
    final desc =
        <String, Object?>{
              'type': queryTypeToJs(type),
              'count': count,
              if (label.isNotEmpty) 'label': label,
            }.jsify()
            as JSObject;
    return WebGpuQuerySet(_js.createQuerySet(desc));
  }

  @override
  WebGpuBindGroupLayout createBindGroupLayout(
    List<GpuBindGroupLayoutEntry> entries, {
    String label = '',
  }) {
    final jsEntries = <Map<String, Object?>>[];
    for (final e in entries) {
      final jsEntry = <String, Object?>{
        'binding': e.binding,
        'visibility': e.visibility as int,
      };
      switch (e) {
        case GpuBufferBindingLayout(
          :final type,
          :final hasDynamicOffset,
          :final minBindingSize,
        ):
          jsEntry['buffer'] = <String, Object?>{
            'type': bufferBindingTypeToJs(type),
            if (hasDynamicOffset) 'hasDynamicOffset': true,
            if (minBindingSize > 0) 'minBindingSize': minBindingSize,
          };
        case GpuSamplerBindingLayout(:final type):
          jsEntry['sampler'] = <String, Object?>{
            'type': samplerBindingTypeToJs(type),
          };
        case GpuTextureBindingLayout(
          :final sampleType,
          :final viewDimension,
          :final multisampled,
        ):
          jsEntry['texture'] = <String, Object?>{
            'sampleType': textureSampleTypeToJs(sampleType),
            'viewDimension': textureViewDimensionToJs(viewDimension),
            if (multisampled) 'multisampled': true,
          };
        case GpuStorageTextureBindingLayout(
          :final access,
          :final format,
          :final viewDimension,
        ):
          jsEntry['storageTexture'] = <String, Object?>{
            'access': storageTextureAccessToJs(access),
            'format': textureFormatToJs(format),
            'viewDimension': textureViewDimensionToJs(viewDimension),
          };
      }
      jsEntries.add(jsEntry);
    }
    final desc =
        <String, Object?>{
              'entries': jsEntries,
              if (label.isNotEmpty) 'label': label,
            }.jsify()
            as JSObject;
    return WebGpuBindGroupLayout(_js.createBindGroupLayout(desc));
  }

  @override
  WebGpuBindGroup createBindGroup({
    required GpuBindGroupLayout layout,
    required List<GpuBindGroupEntry> entries,
    String label = '',
  }) {
    final jsEntries = <Map<String, Object?>>[];
    for (final e in entries) {
      final jsEntry = <String, Object?>{'binding': e.binding};
      switch (e) {
        case GpuBufferBinding(:final buffer, :final offset, :final size):
          jsEntry['resource'] = <String, Object?>{
            'buffer': (buffer as WebGpuBuffer).jsBuffer,
            if (offset > 0) 'offset': offset,
            if (size != null) 'size': size,
          };
        case GpuSamplerBinding(:final sampler):
          jsEntry['resource'] = (sampler as WebGpuSampler).jsSampler;
        case GpuTextureViewBinding(:final view):
          jsEntry['resource'] = (view as WebGpuTextureView).jsView;
      }
      jsEntries.add(jsEntry);
    }
    final desc =
        <String, Object?>{
              'layout': (layout as WebGpuBindGroupLayout).jsLayout,
              'entries': jsEntries,
              if (label.isNotEmpty) 'label': label,
            }.jsify()
            as JSObject;
    return WebGpuBindGroup(_js.createBindGroup(desc));
  }

  @override
  WebGpuPipelineLayout createPipelineLayout(
    List<GpuBindGroupLayout?> layouts, {
    String label = '',
  }) {
    final desc =
        <String, Object?>{
              'bindGroupLayouts': [
                for (final l in layouts)
                  (l as WebGpuBindGroupLayout?)?.jsLayout,
              ],
              if (label.isNotEmpty) 'label': label,
            }.jsify()
            as JSObject;
    return WebGpuPipelineLayout(_js.createPipelineLayout(desc));
  }

  @override
  WebGpuComputePipeline createComputePipeline({
    required GpuShaderModule module,
    String? entryPoint,
    Map<String, double> constants = const {},
    required GpuPipelineLayout? layout,
    String label = '',
  }) {
    final compute = <String, Object?>{
      'module': (module as WebGpuShaderModule).jsModule,
      if (entryPoint != null) 'entryPoint': entryPoint,
      if (constants.isNotEmpty) 'constants': constants,
    };
    final desc =
        <String, Object?>{
              'compute': compute,
              'layout': layout == null
                  ? 'auto'
                  : (layout as WebGpuPipelineLayout).jsLayout,
              if (label.isNotEmpty) 'label': label,
            }.jsify()
            as JSObject;
    return WebGpuComputePipeline(_js.createComputePipeline(desc));
  }

  @override
  WebGpuRenderPipeline createRenderPipeline(
    GpuRenderPipelineDescriptor descriptor,
  ) {
    final desc = _renderPipelineDescToJs(descriptor);
    return WebGpuRenderPipeline(_js.createRenderPipeline(desc));
  }

  @override
  Future<WebGpuComputePipeline> createComputePipelineAsync({
    required GpuShaderModule module,
    String? entryPoint,
    Map<String, double> constants = const {},
    required GpuPipelineLayout? layout,
    String label = '',
  }) async {
    final compute = <String, Object?>{
      'module': (module as WebGpuShaderModule).jsModule,
      if (entryPoint != null) 'entryPoint': entryPoint,
      if (constants.isNotEmpty) 'constants': constants,
    };
    final desc =
        <String, Object?>{
              'compute': compute,
              'layout': layout == null
                  ? 'auto'
                  : (layout as WebGpuPipelineLayout).jsLayout,
              if (label.isNotEmpty) 'label': label,
            }.jsify()
            as JSObject;
    final jsPipeline = await _js.createComputePipelineAsync(desc).toDart;
    return WebGpuComputePipeline(jsPipeline);
  }

  @override
  WebGpuRenderBundleEncoder createRenderBundleEncoder(
    GpuRenderBundleEncoderDescriptor descriptor,
  ) {
    final desc =
        <String, Object?>{
              'colorFormats': [
                for (final f in descriptor.colorFormats)
                  f == null ? null : textureFormatToJs(f),
              ],
              if (descriptor.depthStencilFormat != null)
                'depthStencilFormat': textureFormatToJs(
                  descriptor.depthStencilFormat!,
                ),
              if (descriptor.sampleCount != 1)
                'sampleCount': descriptor.sampleCount,
              if (descriptor.depthReadOnly) 'depthReadOnly': true,
              if (descriptor.stencilReadOnly) 'stencilReadOnly': true,
              if (descriptor.label.isNotEmpty) 'label': descriptor.label,
            }.jsify()
            as JSObject;
    return WebGpuRenderBundleEncoder(_js.createRenderBundleEncoder(desc));
  }

  @override
  Future<WebGpuRenderPipeline> createRenderPipelineAsync(
    GpuRenderPipelineDescriptor descriptor,
  ) async {
    final desc = _renderPipelineDescToJs(descriptor);
    final jsPipeline = await _js.createRenderPipelineAsync(desc).toDart;
    return WebGpuRenderPipeline(jsPipeline);
  }

  @override
  Future<GpuDeviceLostInfo> get lost async {
    final jsInfo = await _js.lost.toDart;
    final info = _JsDeviceLostInfo(jsInfo as JSObject);
    return GpuDeviceLostInfo(
      reason: deviceLostReasonFromJs(info.reason),
      message: info.message,
    );
  }

  @override
  void pushErrorScope(GpuErrorFilter filter) {
    _js.pushErrorScope(errorFilterToJs(filter));
  }

  @override
  Future<GpuError?> popErrorScope() async {
    final jsError = await _js.popErrorScope().toDart;
    if (jsError == null) return null;
    final err = _JsGpuError(jsError);
    return GpuValidationError(err.message);
  }

  @override
  Stream<GpuError> get onUncapturedError => _uncapturedErrorController.stream;

  @override
  void destroy() {
    _js.onuncapturederror = null;
    _uncapturedErrorController.close();
    _js.destroy();
  }
}

JSObject _renderPipelineDescToJs(GpuRenderPipelineDescriptor d) {
  final vertex = <String, Object?>{
    'module': (d.vertexModule as WebGpuShaderModule).jsModule,
    if (d.vertexEntryPoint != null) 'entryPoint': d.vertexEntryPoint,
    if (d.vertexConstants.isNotEmpty) 'constants': d.vertexConstants,
    if (d.vertexBuffers.isNotEmpty)
      'buffers': [
        for (final vb in d.vertexBuffers)
          if (vb == null)
            null
          else
            <String, Object?>{
              'arrayStride': vb.arrayStride,
              'stepMode': vertexStepModeToJs(vb.stepMode),
              'attributes': [
                for (final a in vb.attributes)
                  <String, Object?>{
                    'format': vertexFormatToJs(a.format),
                    'offset': a.offset,
                    'shaderLocation': a.shaderLocation,
                  },
              ],
            },
      ],
  };

  final desc = <String, Object?>{
    'vertex': vertex,
    'layout': d.layout == null
        ? 'auto'
        : (d.layout as WebGpuPipelineLayout).jsLayout,
    'primitive': <String, Object?>{
      'topology': primitiveTopologyToJs(d.primitiveTopology),
      if (d.stripIndexFormat != null)
        'stripIndexFormat': indexFormatToJs(d.stripIndexFormat!),
      'frontFace': frontFaceToJs(d.frontFace),
      'cullMode': cullModeToJs(d.cullMode),
      if (d.unclippedDepth) 'unclippedDepth': true,
    },
    if (d.multisampleCount != 1 ||
        d.multisampleMask != 0xFFFFFFFF ||
        d.alphaToCoverageEnabled)
      'multisample': <String, Object?>{
        'count': d.multisampleCount,
        'mask': d.multisampleMask,
        if (d.alphaToCoverageEnabled) 'alphaToCoverageEnabled': true,
      },
    if (d.label.isNotEmpty) 'label': d.label,
  };

  if (d.fragmentModule != null) {
    desc['fragment'] = <String, Object?>{
      'module': (d.fragmentModule as WebGpuShaderModule).jsModule,
      if (d.fragmentEntryPoint != null) 'entryPoint': d.fragmentEntryPoint,
      if (d.fragmentConstants.isNotEmpty) 'constants': d.fragmentConstants,
      'targets': [
        for (final ct in d.colorTargets)
          if (ct == null)
            null
          else
            <String, Object?>{
              'format': textureFormatToJs(ct.format),
              if (ct.blend != null)
                'blend': <String, Object?>{
                  'color': _blendComponentToJs(ct.blend!.color),
                  'alpha': _blendComponentToJs(ct.blend!.alpha),
                },
              'writeMask': ct.writeMask,
            },
      ],
    };
  }

  if (d.depthStencil != null) {
    final ds = d.depthStencil!;
    desc['depthStencil'] = <String, Object?>{
      'format': textureFormatToJs(ds.format),
      if (ds.depthWriteEnabled != null)
        'depthWriteEnabled': ds.depthWriteEnabled,
      if (ds.depthCompare != null)
        'depthCompare': compareFunctionToJs(ds.depthCompare!),
      'depthBias': ds.depthBias,
      'depthBiasSlopeScale': ds.depthBiasSlopeScale,
      'depthBiasClamp': ds.depthBiasClamp,
      'stencilFront': _stencilFaceToJs(ds.stencilFront),
      'stencilBack': _stencilFaceToJs(ds.stencilBack),
      'stencilReadMask': ds.stencilReadMask,
      'stencilWriteMask': ds.stencilWriteMask,
    };
  }

  return desc.jsify() as JSObject;
}

Map<String, Object?> _blendComponentToJs(GpuBlendComponent c) => {
  'operation': blendOperationToJs(c.operation),
  'srcFactor': blendFactorToJs(c.srcFactor),
  'dstFactor': blendFactorToJs(c.dstFactor),
};

Map<String, Object?> _stencilFaceToJs(GpuStencilFaceState s) => {
  'compare': compareFunctionToJs(s.compare),
  'failOp': stencilOperationToJs(s.failOp),
  'depthFailOp': stencilOperationToJs(s.depthFailOp),
  'passOp': stencilOperationToJs(s.passOp),
};

extension type _JsDeviceLostInfo(JSObject _) implements JSObject {
  external String get reason;
  external String get message;
}

extension type _JsGpuError(JSObject _) implements JSObject {
  external String get message;
  external JSObject get constructor;
}

extension type _JsGpuUncapturedErrorEvent(JSObject _) implements JSObject {
  external _JsGpuError get error;
}

extension on JSObject {
  external String get name;
}
