import 'dart:js_interop';

import 'package:gpuweb/gpuweb.dart';

import 'convert.dart';
import 'js/webgpu.dart';
import 'device.dart';

/// Web implementation of [GpuAdapter].
class WebGpuAdapter implements GpuAdapter {
  WebGpuAdapter(this._js);

  final JsGpuAdapter _js;

  @override
  Set<GpuFeatureName> get features => _readFeatureSet(_js.features);

  @override
  GpuLimits get limits => _limitsFromJs(_js.limits);

  @override
  GpuAdapterInfo get info {
    final i = _js.info;
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
  Future<WebGpuDevice> requestDevice([
    GpuDeviceDescriptor descriptor = const GpuDeviceDescriptor(),
  ]) async {
    final jsDesc = <String, Object?>{};
    if (descriptor.label.isNotEmpty) {
      jsDesc['label'] = descriptor.label;
    }
    if (descriptor.requiredFeatures.isNotEmpty) {
      jsDesc['requiredFeatures'] = [
        for (final f in descriptor.requiredFeatures) featureNameToJs(f),
      ];
    }
    if (descriptor.requiredLimits != null) {
      jsDesc['requiredLimits'] = _limitsToJsMap(descriptor.requiredLimits!);
    }
    if (descriptor.defaultQueueLabel.isNotEmpty) {
      jsDesc['defaultQueue'] = {'label': descriptor.defaultQueueLabel};
    }

    final jsOpts = jsDesc.isEmpty ? null : jsDesc.jsify() as JSObject;
    final jsDevice = await _js.requestDevice(jsOpts).toDart;
    return WebGpuDevice(jsDevice);
  }
}

Set<GpuFeatureName> _readFeatureSet(JSObject jsFeatures) {
  final setLike = JsSetLike(jsFeatures);
  final result = <GpuFeatureName>{};
  for (final f in GpuFeatureName.values) {
    if (setLike.has(featureNameToJs(f))) {
      result.add(f);
    }
  }
  return result;
}

GpuLimits _limitsFromJs(JsGpuSupportedLimits l) => GpuLimits(
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

Map<String, int> _limitsToJsMap(GpuLimits l) => {
  if (l.maxTextureDimension1d > 0)
    'maxTextureDimension1D': l.maxTextureDimension1d,
  if (l.maxTextureDimension2d > 0)
    'maxTextureDimension2D': l.maxTextureDimension2d,
  if (l.maxTextureDimension3d > 0)
    'maxTextureDimension3D': l.maxTextureDimension3d,
  if (l.maxTextureArrayLayers > 0)
    'maxTextureArrayLayers': l.maxTextureArrayLayers,
  if (l.maxBindGroups > 0) 'maxBindGroups': l.maxBindGroups,
  if (l.maxBindingsPerBindGroup > 0)
    'maxBindingsPerBindGroup': l.maxBindingsPerBindGroup,
  if (l.maxUniformBufferBindingSize > 0)
    'maxUniformBufferBindingSize': l.maxUniformBufferBindingSize,
  if (l.maxStorageBufferBindingSize > 0)
    'maxStorageBufferBindingSize': l.maxStorageBufferBindingSize,
  if (l.maxComputeWorkgroupsPerDimension > 0)
    'maxComputeWorkgroupsPerDimension': l.maxComputeWorkgroupsPerDimension,
  if (l.maxBufferSize > 0) 'maxBufferSize': l.maxBufferSize,
};
