import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:gpuweb/gpuweb.dart';
import '../wgpu_ffi.dart' show wgpuLastError;
import 'ffi/bindings_generated.dart' as ffi;
import 'resource.dart';
import 'instance.dart';
import 'device.dart';
import 'queue.dart';

/// Convert a GpuFeatureName bitmask from FFI to a Dart Set.
Set<GpuFeatureName> featuresFromBitmask(int bits) {
  final result = <GpuFeatureName>{};
  for (final feature in GpuFeatureName.values) {
    if (bits & (1 << feature.index) != 0) {
      result.add(feature);
    }
  }
  return result;
}

/// Convert a Dart Set of GpuFeatureName to a bitmask for FFI.
int featuresToBitmask(Set<GpuFeatureName> features) {
  var bits = 0;
  for (final feature in features) {
    bits |= 1 << feature.index;
  }
  return bits;
}

/// Convert a WGPUDeviceLimits FFI struct to a GpuLimits object.
GpuLimits limitsFromFfi(ffi.WGPUDeviceLimits n) => GpuLimits(
  maxTextureDimension1d: n.max_texture_dimension_1d,
  maxTextureDimension2d: n.max_texture_dimension_2d,
  maxTextureDimension3d: n.max_texture_dimension_3d,
  maxTextureArrayLayers: n.max_texture_array_layers,
  maxBindGroups: n.max_bind_groups,
  maxBindGroupsPlusVertexBuffers: n.max_bind_groups_plus_vertex_buffers,
  maxBindingsPerBindGroup: n.max_bindings_per_bind_group,
  maxDynamicUniformBuffersPerPipelineLayout:
      n.max_dynamic_uniform_buffers_per_pipeline_layout,
  maxDynamicStorageBuffersPerPipelineLayout:
      n.max_dynamic_storage_buffers_per_pipeline_layout,
  maxSampledTexturesPerShaderStage: n.max_sampled_textures_per_shader_stage,
  maxSamplersPerShaderStage: n.max_samplers_per_shader_stage,
  maxStorageBuffersPerShaderStage: n.max_storage_buffers_per_shader_stage,
  maxStorageTexturesPerShaderStage: n.max_storage_textures_per_shader_stage,
  maxUniformBuffersPerShaderStage: n.max_uniform_buffers_per_shader_stage,
  maxUniformBufferBindingSize: n.max_uniform_buffer_binding_size,
  maxStorageBufferBindingSize: n.max_storage_buffer_binding_size,
  minUniformBufferOffsetAlignment: n.min_uniform_buffer_offset_alignment,
  minStorageBufferOffsetAlignment: n.min_storage_buffer_offset_alignment,
  maxVertexBuffers: n.max_vertex_buffers,
  maxBufferSize: n.max_buffer_size,
  maxVertexAttributes: n.max_vertex_attributes,
  maxVertexBufferArrayStride: n.max_vertex_buffer_array_stride,
  maxInterStageShaderVariables: n.max_inter_stage_shader_variables,
  maxColorAttachments: n.max_color_attachments,
  maxColorAttachmentBytesPerSample: n.max_color_attachment_bytes_per_sample,
  maxComputeWorkgroupStorageSize: n.max_compute_workgroup_storage_size,
  maxComputeInvocationsPerWorkgroup: n.max_compute_invocations_per_workgroup,
  maxComputeWorkgroupSizeX: n.max_compute_workgroup_size_x,
  maxComputeWorkgroupSizeY: n.max_compute_workgroup_size_y,
  maxComputeWorkgroupSizeZ: n.max_compute_workgroup_size_z,
  maxComputeWorkgroupsPerDimension: n.max_compute_workgroups_per_dimension,
);

/// Write a GpuLimits object to an FFI WGPUDeviceLimits struct.
void limitsToFfi(Pointer<ffi.WGPUDeviceLimits> ptr, GpuLimits limits) {
  ptr.ref.max_texture_dimension_1d = limits.maxTextureDimension1d;
  ptr.ref.max_texture_dimension_2d = limits.maxTextureDimension2d;
  ptr.ref.max_texture_dimension_3d = limits.maxTextureDimension3d;
  ptr.ref.max_texture_array_layers = limits.maxTextureArrayLayers;
  ptr.ref.max_bind_groups = limits.maxBindGroups;
  ptr.ref.max_bind_groups_plus_vertex_buffers =
      limits.maxBindGroupsPlusVertexBuffers;
  ptr.ref.max_bindings_per_bind_group = limits.maxBindingsPerBindGroup;
  ptr.ref.max_dynamic_uniform_buffers_per_pipeline_layout =
      limits.maxDynamicUniformBuffersPerPipelineLayout;
  ptr.ref.max_dynamic_storage_buffers_per_pipeline_layout =
      limits.maxDynamicStorageBuffersPerPipelineLayout;
  ptr.ref.max_sampled_textures_per_shader_stage =
      limits.maxSampledTexturesPerShaderStage;
  ptr.ref.max_samplers_per_shader_stage = limits.maxSamplersPerShaderStage;
  ptr.ref.max_storage_buffers_per_shader_stage =
      limits.maxStorageBuffersPerShaderStage;
  ptr.ref.max_storage_textures_per_shader_stage =
      limits.maxStorageTexturesPerShaderStage;
  ptr.ref.max_uniform_buffers_per_shader_stage =
      limits.maxUniformBuffersPerShaderStage;
  ptr.ref.max_uniform_buffer_binding_size = limits.maxUniformBufferBindingSize;
  ptr.ref.max_storage_buffer_binding_size = limits.maxStorageBufferBindingSize;
  ptr.ref.min_uniform_buffer_offset_alignment =
      limits.minUniformBufferOffsetAlignment;
  ptr.ref.min_storage_buffer_offset_alignment =
      limits.minStorageBufferOffsetAlignment;
  ptr.ref.max_vertex_buffers = limits.maxVertexBuffers;
  ptr.ref.max_buffer_size = limits.maxBufferSize;
  ptr.ref.max_vertex_attributes = limits.maxVertexAttributes;
  ptr.ref.max_vertex_buffer_array_stride = limits.maxVertexBufferArrayStride;
  ptr.ref.max_inter_stage_shader_variables =
      limits.maxInterStageShaderVariables;
  ptr.ref.max_color_attachments = limits.maxColorAttachments;
  ptr.ref.max_color_attachment_bytes_per_sample =
      limits.maxColorAttachmentBytesPerSample;
  ptr.ref.max_compute_workgroup_storage_size =
      limits.maxComputeWorkgroupStorageSize;
  ptr.ref.max_compute_invocations_per_workgroup =
      limits.maxComputeInvocationsPerWorkgroup;
  ptr.ref.max_compute_workgroup_size_x = limits.maxComputeWorkgroupSizeX;
  ptr.ref.max_compute_workgroup_size_y = limits.maxComputeWorkgroupSizeY;
  ptr.ref.max_compute_workgroup_size_z = limits.maxComputeWorkgroupSizeZ;
  ptr.ref.max_compute_workgroups_per_dimension =
      limits.maxComputeWorkgroupsPerDimension;
}

/// Graphics backend type (wgpu extension).
enum WgpuBackendType {
  undefined,
  null_,
  webGpu,
  d3d11,
  d3d12,
  metal,
  vulkan,
  openGl,
  openGlEs,
}

/// Adapter type (wgpu extension).
enum WgpuAdapterType {
  discreteGpu,
  integratedGpu,
  cpu,
  unknown,
}

WgpuBackendType _backendFromFfi(int value) => switch (value) {
  1 => WgpuBackendType.vulkan,
  2 => WgpuBackendType.metal,
  3 => WgpuBackendType.d3d12,
  4 => WgpuBackendType.openGl,
  5 => WgpuBackendType.webGpu,
  _ => WgpuBackendType.undefined,
};

WgpuAdapterType _adapterTypeFromFfi(int value) => switch (value) {
  1 => WgpuAdapterType.integratedGpu,
  2 => WgpuAdapterType.discreteGpu,
  4 => WgpuAdapterType.cpu,
  _ => WgpuAdapterType.unknown,
};

/// Extended adapter info with wgpu-specific fields.
class WgpuAdapterInfo extends GpuAdapterInfo {
  WgpuAdapterInfo({
    super.vendor,
    super.architecture,
    super.device,
    super.description,
    this.backendType = WgpuBackendType.undefined,
    this.adapterType = WgpuAdapterType.unknown,
    this.vendorId = 0,
    this.deviceId = 0,
    this.driverApiVersion = 0,
  });

  /// Graphics backend type (Vulkan, Metal, D3D12, etc.).
  final WgpuBackendType backendType;

  /// Adapter type (discrete, integrated, CPU, etc.).
  final WgpuAdapterType adapterType;

  /// PCI vendor ID.
  final int vendorId;

  /// PCI device ID.
  final int deviceId;

  /// Vulkan API version (VK_MAKE_API_VERSION packed u32), 0 on non-Vulkan.
  ///
  /// Decode: major = (v >> 22) & 0x7F, minor = (v >> 12) & 0x3FF, patch = v & 0xFFF.
  final int driverApiVersion;
}

String _ptrToString(Pointer<Char> ptr) =>
    ptr == nullptr ? '' : ptr.cast<Utf8>().toDartString();

/// A GPU adapter - represents a physical GPU.
///
/// Use adapters to query GPU capabilities and request devices:
/// ```dart
/// final adapter = instance.requestAdapter();
/// print(adapter.info.backendType); // WgpuBackendType.metal
/// final device = adapter.requestDevice();
/// final queue = device.queue;
/// ```
class WgpuAdapter implements GpuAdapter, WgpuResource {
  final int _handle;
  bool _disposed = false;

  /// Retained to prevent garbage collection - wgpu requires instance to outlive adapter.
  // ignore: unused_field
  final Wgpu _instance;

  WgpuAdapter.internal(this._handle, this._instance);

  /// The native handle for this adapter.
  int get handle => _handle;

  @override
  bool get isDisposed => _disposed;

  /// The feature level supported by this adapter (wgpu extension).
  ///
  /// Always "core" for wgpu adapters.
  String get featureLevel => 'core';

  @override
  Set<GpuFeatureName> get features =>
      featuresFromBitmask(ffi.wgpun_AdapterGetFeatures(_handle));

  @override
  WgpuAdapterInfo get info {
    final n = ffi.wgpun_AdapterGetInfo(_handle);
    return WgpuAdapterInfo(
      vendor: _ptrToString(n.vendor),
      architecture: _ptrToString(n.architecture),
      device: _ptrToString(n.device),
      description: _ptrToString(n.description),
      backendType: _backendFromFfi(n.backend_type),
      adapterType: _adapterTypeFromFfi(n.adapter_type),
      vendorId: n.vendor_id,
      deviceId: n.device_id,
      driverApiVersion: n.driver_api_version,
    );
  }

  @override
  GpuLimits get limits => limitsFromFfi(ffi.wgpun_AdapterGetLimits(_handle));

  /// Raw downlevel capability flags from wgpu.
  ///
  /// Returns the bits of `wgpu::DownlevelFlags`. Use with gpux's
  /// [GpuDownlevel] class for a typed API.
  int get downlevelFlags => ffi.wgpun_AdapterGetDownlevelFlags(_handle);

  @override
  Future<WgpuDevice> requestDevice([
    GpuDeviceDescriptor descriptor = const GpuDeviceDescriptor(),
  ]) async {
    return using((arena) {
      final desc = arena<ffi.WGPUDeviceDescriptor>();
      desc.ref.required_features = featuresToBitmask(
        descriptor.requiredFeatures,
      );
      if (descriptor.requiredLimits != null) {
        final limitsPtr = arena<ffi.WGPUDeviceLimits>();
        limitsToFfi(limitsPtr, descriptor.requiredLimits!);
        desc.ref.required_limits = limitsPtr;
      } else {
        desc.ref.required_limits = nullptr;
      }

      // wgpu extensions via WgpuDeviceDescriptor.
      if (descriptor case WgpuDeviceDescriptor(
        :final bindlessTextures,
        :final immediates,
      )) {
        desc.ref.bindless_textures = bindlessTextures ? 1 : 0;
        desc.ref.immediates = immediates ? 1 : 0;
      } else {
        desc.ref.bindless_textures = 0;
        desc.ref.immediates = 0;
      }

      final deviceHandle = ffi.wgpun_AdapterRequestDevice(_handle, desc);

      if (deviceHandle == 0) {
        throw StateError('Failed to request device: ${wgpuLastError()}');
      }

      final queueHandle = ffi.wgpun_DeviceGetQueue(deviceHandle);
      if (queueHandle == 0) {
        throw StateError('Failed to get queue for device');
      }

      final actualFeatures = featuresFromBitmask(
        ffi.wgpun_DeviceGetFeatures(deviceHandle),
      );
      final actualLimits = limitsFromFfi(
        ffi.wgpun_DeviceGetLimits(deviceHandle),
      );

      final queue = WgpuQueue.fromHandle(
        queueHandle,
        deviceHandle: deviceHandle,
      );
      return WgpuDevice.fromHandle(
        deviceHandle,
        adapter: this,
        queue: queue,
        features: actualFeatures,
        limits: actualLimits,
      );
    });
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ffi.wgpun_AdapterRelease(_handle);
  }
}

/// Device descriptor with wgpu extensions.
///
/// Pass to [WgpuAdapter.requestDevice] to enable wgpu-specific features.
class WgpuDeviceDescriptor extends GpuDeviceDescriptor {
  const WgpuDeviceDescriptor({
    super.label,
    super.requiredFeatures,
    super.requiredLimits,
    super.defaultQueueLabel,
    this.bindlessTextures = false,
    this.immediates = false,
  });

  /// Enable texture binding arrays.
  final bool bindlessTextures;

  /// Enable immediates / push constants (`var<immediate>` in WGSL).
  final bool immediates;
}
