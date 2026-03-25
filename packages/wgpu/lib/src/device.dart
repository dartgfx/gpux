import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:gpuweb/gpuweb.dart';
import 'ffi/bindings_generated.dart' as ffi;
import 'ffi/enum_ffi.dart';
import 'bind_group.dart';
import 'buffer.dart';
import 'texture.dart';
import 'sampler.dart';
import 'shader.dart';
import 'encoder.dart';
import 'query_set.dart';
import 'pipeline.dart';
import '../wgpu_ffi.dart' show wgpuLastError;
import 'adapter.dart';
import 'queue.dart';

/// A logical GPU device for creating resources.
///
/// Create via the explicit instance → adapter → device chain:
/// ```dart
/// final instance = Wgpu.create();
/// final adapter = instance.requestAdapter();
/// final device = adapter.requestDevice();
/// final queue = device.queue;
/// ```
class WgpuDevice implements GpuDevice {
  final int _handle;

  /// The adapter this device was created from.
  /// Retained to prevent garbage collection - wgpu requires adapter to outlive device.
  // ignore: unused_field
  final WgpuAdapter? _adapter;

  final WgpuQueue? _queue;
  final Set<GpuFeatureName> _features;
  final GpuLimits _limits;
  final GpuAdapterInfo _adapterInfo;

  /// Create a device from a native handle.
  ///
  /// [adapter] is retained to prevent garbage collection (wgpu requires adapter
  /// to outlive device).
  WgpuDevice.fromHandle(
    int handle, {
    WgpuAdapter? adapter,
    WgpuQueue? queue,
    Set<GpuFeatureName> features = const {},
    GpuLimits? limits,
    GpuAdapterInfo? adapterInfo,
  }) : _handle = handle,
       _adapter = adapter,
       _queue = queue,
       _features = features,
       _limits = limits ?? GpuLimits(),
       _adapterInfo = adapterInfo ?? GpuAdapterInfo();

  @override
  Set<GpuFeatureName> get features => _features;

  @override
  GpuLimits get limits => _limits;

  @override
  GpuAdapterInfo get adapterInfo => _adapterInfo;

  /// The command queue for this device.
  ///
  /// In WebGPU, each device has exactly one queue.
  @override
  WgpuQueue get queue => _queue!;

  /// The native handle.
  int get handle => _handle;

  /// Creates a GPU buffer.
  @override
  WgpuBuffer createBuffer({
    required int size,
    required GpuBufferUsageFlags usage,
    bool mappedAtCreation = false,
    String label = '',
  }) {
    if (size <= 0) throw ArgumentError('size must be positive');
    if (usage == 0) throw ArgumentError('usage must not be 0');
    return using((arena) {
      final desc = arena<ffi.WGPUBufferDescriptor>();
      desc.ref.size = size;
      desc.ref.usage = usage;
      desc.ref.mapped_at_creation = mappedAtCreation ? 1 : 0;
      if (label.isNotEmpty) {
        desc.ref.label = label.toNativeUtf8(allocator: arena).cast();
      }

      final handle = ffi.wgpun_DeviceCreateBuffer(_handle, desc);

      if (handle == 0) {
        throw StateError('Failed to create buffer: ${wgpuLastError()}');
      }

      return WgpuBuffer.internal(
        handle,
        _handle,
        size,
        usage,
        label: label,
      );
    });
  }

  /// Creates a texture.
  ///
  /// [viewFormats] allows creating views with a different format than [format].
  /// For example, creating a texture with [GpuTextureFormat.rgba8Unorm] and
  /// `viewFormats: [GpuTextureFormat.rgba8UnormSrgb]` allows sampling with
  /// sRGB decoding while still supporting storage writes in linear.
  @override
  WgpuTexture createTexture({
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
    if (width <= 0) throw ArgumentError('width must be positive');
    if (height <= 0) throw ArgumentError('height must be positive');
    if (depthOrArrayLayers <= 0) {
      throw ArgumentError('depthOrArrayLayers must be positive');
    }
    if (mipLevelCount <= 0) {
      throw ArgumentError('mipLevelCount must be positive');
    }
    if (usage == 0) throw ArgumentError('usage must not be 0');
    return using((arena) {
      final desc = arena<ffi.WGPUTextureDescriptor>();
      desc.ref.width = width;
      desc.ref.height = height;
      desc.ref.depth_or_array_layers = depthOrArrayLayers;
      desc.ref.mip_level_count = mipLevelCount;
      desc.ref.sample_count = sampleCount;
      desc.ref.dimension = dimension.ffiValue;
      desc.ref.format = format.ffiValue;
      desc.ref.usage = usage;

      if (viewFormats.isNotEmpty) {
        final formatsPtr = arena<Uint32>(viewFormats.length);
        for (var i = 0; i < viewFormats.length; i++) {
          formatsPtr[i] = viewFormats[i].ffiValue;
        }
        desc.ref.view_format_count = viewFormats.length;
        desc.ref.view_formats = formatsPtr;
      } else {
        desc.ref.view_format_count = 0;
        desc.ref.view_formats = nullptr;
      }
      if (label.isNotEmpty) {
        desc.ref.label = label.toNativeUtf8(allocator: arena).cast();
      }

      final handle = ffi.wgpun_DeviceCreateTexture(_handle, desc);

      if (handle == 0) {
        throw StateError('Failed to create texture: ${wgpuLastError()}');
      }

      return WgpuTexture.internal(
        handle,
        width: width,
        height: height,
        depthOrArrayLayers: depthOrArrayLayers,
        dimension: dimension,
        format: format,
        usage: usage,
        mipLevelCount: mipLevelCount,
        sampleCount: sampleCount,
        label: label,
        textureBindingViewDimension: textureBindingViewDimension,
      );
    });
  }

  /// Creates a sampler.
  ///
  /// For comparison samplers (shadow mapping), set [compare] to the desired
  /// comparison function (e.g., [GpuCompareFunction.less]).
  @override
  WgpuSampler createSampler({
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
    return using((arena) {
      final desc = arena<ffi.WGPUSamplerDescriptor>();
      desc.ref.address_mode_u = addressModeU.ffiValue;
      desc.ref.address_mode_v = addressModeV.ffiValue;
      desc.ref.address_mode_w = addressModeW.ffiValue;
      desc.ref.mag_filter = magFilter.ffiValue;
      desc.ref.min_filter = minFilter.ffiValue;
      desc.ref.mipmap_filter = mipmapFilter.ffiValue;
      desc.ref.lod_min_clamp = lodMinClamp;
      desc.ref.lod_max_clamp = lodMaxClamp;
      desc.ref.compare = compare?.ffiValue ?? 0;
      desc.ref.max_anisotropy = maxAnisotropy;
      if (label.isNotEmpty) {
        desc.ref.label = label.toNativeUtf8(allocator: arena).cast();
      }

      final handle = ffi.wgpun_DeviceCreateSampler(_handle, desc);

      if (handle == 0) {
        throw StateError('Failed to create sampler: ${wgpuLastError()}');
      }

      return WgpuSampler.internal(handle, label: label);
    });
  }

  /// Creates a shader module from WGSL source.
  @override
  WgpuShaderModule createShaderModule(String wgslSource, {String label = ''}) {
    return using((arena) {
      final sourcePtr = wgslSource.toNativeUtf8(allocator: arena);
      final sourceByteLength = sourcePtr.length;
      final labelPtr = label.isEmpty
          ? nullptr
          : label.toNativeUtf8(allocator: arena).cast<Char>();
      final handle = ffi.wgpun_DeviceCreateShaderModule(
        _handle,
        sourcePtr.cast(),
        sourceByteLength,
        labelPtr,
      );

      if (handle == 0) {
        throw StateError('Failed to create shader module: ${wgpuLastError()}');
      }

      return WgpuShaderModule.internal(handle, label: label);
    });
  }

  /// Creates a command encoder.
  @override
  WgpuCommandEncoder createCommandEncoder({String label = ''}) {
    return using((arena) {
      final labelPtr = label.isEmpty
          ? nullptr
          : label.toNativeUtf8(allocator: arena).cast<Char>();
      final handle = ffi.wgpun_DeviceCreateCommandEncoder(
        _handle,
        labelPtr,
      );

      if (handle == 0) {
        throw StateError(
          'Failed to create command encoder: ${wgpuLastError()}',
        );
      }

      return WgpuCommandEncoder.internal(handle, label: label);
    });
  }

  @override
  WgpuRenderBundleEncoder createRenderBundleEncoder(
    GpuRenderBundleEncoderDescriptor descriptor,
  ) {
    return using((arena) {
      final desc = arena<ffi.WGPURenderBundleEncoderDescriptor>();

      final colorFormats = descriptor.colorFormats;
      if (colorFormats.isNotEmpty) {
        final formatsPtr = arena<Uint32>(colorFormats.length);
        for (var i = 0; i < colorFormats.length; i++) {
          formatsPtr[i] = colorFormats[i]?.ffiValue ?? 0xFFFFFFFF;
        }
        desc.ref.color_formats = formatsPtr;
        desc.ref.color_format_count = colorFormats.length;
      }

      desc.ref.depth_stencil_format =
          descriptor.depthStencilFormat?.ffiValue ?? 0;
      desc.ref.sample_count = descriptor.sampleCount;
      desc.ref.depth_read_only = descriptor.depthReadOnly ? 1 : 0;
      desc.ref.stencil_read_only = descriptor.stencilReadOnly ? 1 : 0;

      if (descriptor.label.isNotEmpty) {
        desc.ref.label = descriptor.label.toNativeUtf8(allocator: arena).cast();
      }

      final handle = ffi.wgpun_DeviceCreateRenderBundleEncoder(
        _handle,
        desc,
      );

      if (handle == 0) {
        throw StateError(
          'Failed to create render bundle encoder: ${wgpuLastError()}',
        );
      }

      return WgpuRenderBundleEncoder.internal(handle, label: descriptor.label);
    });
  }

  @override
  void destroy() {
    // wgpu device is cleaned up via handle dropping — no-op for now.
  }

  /// Pop one captured device error, or null if none (wgpu extension).
  ///
  /// Device errors (validation failures, OOM) are captured automatically.
  /// Call after operations that may fail (pipeline creation, draw) to check.
  String? popError() {
    final ptr = ffi.wgpun_DevicePopError(_handle);
    if (ptr == nullptr) return null;
    return ptr.cast<Utf8>().toDartString();
  }

  /// Get all captured device errors, clearing the queue (wgpu extension).
  List<String> get errors {
    final result = <String>[];
    for (;;) {
      final error = popError();
      if (error == null) break;
      result.add(error);
    }
    return result;
  }

  /// Polls the device for completed GPU work (wgpu extension).
  ///
  /// If [wait] is true (default), blocks until all submitted work is done.
  /// If [wait] is false, returns immediately after processing completed work.
  void poll({bool wait = true}) {
    ffi.wgpun_DevicePoll(_handle, wait ? 1 : 0);
  }

  /// Creates a query set for GPU profiling or occlusion testing.
  ///
  /// [type] specifies the query type (default: timestamp).
  /// [count] is the number of query slots.
  @override
  WgpuQuerySet createQuerySet({
    required GpuQueryType type,
    required int count,
    String label = '',
  }) {
    return using((arena) {
      final labelPtr = label.isEmpty
          ? nullptr
          : label.toNativeUtf8(allocator: arena).cast<Char>();
      final handle = ffi.wgpun_DeviceCreateQuerySet(
        _handle,
        type.ffiValue,
        count,
        labelPtr,
      );

      if (handle == 0) {
        throw StateError('Failed to create query set: ${wgpuLastError()}');
      }

      return WgpuQuerySet.internal(handle, type, count, label: label);
    });
  }

  /// Creates a bind group layout.
  ///
  /// [bindingArraySizes] maps binding index → array size for wgpu
  /// binding arrays (not part of the WebGPU JS spec).
  @override
  WgpuBindGroupLayout createBindGroupLayout(
    List<GpuBindGroupLayoutEntry> entries, {
    Map<int, int>? bindingArraySizes,
    String label = '',
  }) {
    for (final entry in entries) {
      if (entry.binding < 0) {
        throw ArgumentError('binding index must be non-negative');
      }
    }

    return using((arena) {
      final entriesPtr = arena<ffi.WGPUBindGroupLayoutEntry>(entries.length);
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        final p = entriesPtr[i];
        p.binding = e.binding;
        p.visibility = e.visibility;
        p.count = bindingArraySizes?[e.binding] ?? 0;
        switch (e) {
          case GpuBufferBindingLayout():
            p.binding_type = 0; // BINDING_TYPE_BUFFER
            p.buffer_type = e.type.ffiValue;
            p.has_dynamic_offset = e.hasDynamicOffset ? 1 : 0;
            p.min_binding_size = e.minBindingSize;
          case GpuSamplerBindingLayout():
            p.binding_type = 1; // BINDING_TYPE_SAMPLER
            p.sampler_type = e.type.ffiValue;
          case GpuTextureBindingLayout():
            p.binding_type = 2; // BINDING_TYPE_TEXTURE
            p.texture_sample_type = e.sampleType.ffiValue;
            p.texture_view_dimension = e.viewDimension.ffiValue;
            p.texture_multisampled = e.multisampled ? 1 : 0;
          case GpuStorageTextureBindingLayout():
            p.binding_type = 3; // BINDING_TYPE_STORAGE_TEXTURE
            p.buffer_type = e.access.ffiValue;
            p.texture_sample_type = e.format.ffiValue;
            p.texture_view_dimension = e.viewDimension.ffiValue;
        }
      }

      final desc = arena<ffi.WGPUBindGroupLayoutDescriptor>();
      desc.ref.entries = entriesPtr;
      desc.ref.entry_count = entries.length;
      if (label.isNotEmpty) {
        desc.ref.label = label.toNativeUtf8(allocator: arena).cast();
      }

      final handle = ffi.wgpun_DeviceCreateBindGroupLayout(
        _handle,
        desc,
      );

      if (handle == 0) {
        throw StateError(
          'Failed to create bind group layout: ${wgpuLastError()}',
        );
      }

      return WgpuBindGroupLayout.internal(handle, label: label);
    });
  }

  /// Creates a bind group.
  @override
  WgpuBindGroup createBindGroup({
    required GpuBindGroupLayout layout,
    required List<GpuBindGroupEntry> entries,
    String label = '',
  }) {
    for (final entry in entries) {
      if (entry.binding < 0) {
        throw ArgumentError('binding index must be non-negative');
      }
    }

    return using((arena) {
      final entriesPtr = arena<ffi.WGPUBindGroupEntry>(entries.length);
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        entriesPtr[i].binding = e.binding;
        switch (e) {
          case GpuBufferBinding(:final buffer, :final offset, :final size):
            entriesPtr[i].resource_type = 0;
            entriesPtr[i].resource = (buffer as WgpuBuffer).handle;
            entriesPtr[i].offset = offset;
            entriesPtr[i].size = size ?? 0;
          case GpuSamplerBinding(:final sampler):
            entriesPtr[i].resource_type = 1;
            entriesPtr[i].resource = (sampler as WgpuSampler).handle;
            entriesPtr[i].offset = 0;
            entriesPtr[i].size = 0;
          case GpuTextureViewBinding(:final view):
            entriesPtr[i].resource_type = 2;
            entriesPtr[i].resource = (view as WgpuTextureView).handle;
            entriesPtr[i].offset = 0;
            entriesPtr[i].size = 0;
          case WgpuTextureViewArrayBinding(:final views):
            entriesPtr[i].resource_type = 4;
            final handlesPtr = arena<Uint64>(views.length);
            for (var j = 0; j < views.length; j++) {
              (handlesPtr + j).value = (views[j] as WgpuTextureView).handle;
            }
            entriesPtr[i].resource = handlesPtr.address;
            entriesPtr[i].size = views.length;
            entriesPtr[i].offset = 0;
          default:
            throw ArgumentError('Unsupported bind group entry type: $e');
        }
      }

      final desc = arena<ffi.WGPUBindGroupDescriptor>();
      desc.ref.layout = (layout as WgpuBindGroupLayout).handle;
      desc.ref.entries = entriesPtr;
      desc.ref.entry_count = entries.length;
      if (label.isNotEmpty) {
        desc.ref.label = label.toNativeUtf8(allocator: arena).cast();
      }

      final handle = ffi.wgpun_DeviceCreateBindGroup(_handle, desc);

      if (handle == 0) {
        throw StateError('Failed to create bind group: ${wgpuLastError()}');
      }

      return WgpuBindGroup.internal(handle, label: label);
    });
  }

  /// Creates a pipeline layout.
  ///
  /// [immediateSize] sets the size in bytes of immediate (push constant) data.
  /// Requires the IMMEDIATES feature to be enabled on the device.
  @override
  WgpuPipelineLayout createPipelineLayout(
    List<GpuBindGroupLayout?> layouts, {
    int immediateSize = 0,
    String label = '',
  }) {
    return using((arena) {
      final layoutsPtr = arena<Uint64>(layouts.length);
      for (var i = 0; i < layouts.length; i++) {
        layoutsPtr[i] = (layouts[i] as WgpuBindGroupLayout?)?.handle ?? 0;
      }

      final desc = arena<ffi.WGPUPipelineLayoutDescriptor>();
      desc.ref.bind_group_layouts = layoutsPtr;
      desc.ref.bind_group_layout_count = layouts.length;
      desc.ref.immediate_size = immediateSize;
      if (label.isNotEmpty) {
        desc.ref.label = label.toNativeUtf8(allocator: arena).cast();
      }

      final handle = ffi.wgpun_DeviceCreatePipelineLayout(_handle, desc);

      if (handle == 0) {
        throw StateError(
          'Failed to create pipeline layout: ${wgpuLastError()}',
        );
      }

      return WgpuPipelineLayout.internal(handle, label: label);
    });
  }

  /// Creates a compute pipeline.
  @override
  WgpuComputePipeline createComputePipeline({
    required GpuShaderModule module,
    String? entryPoint,
    Map<String, double> constants = const {},
    required GpuPipelineLayout? layout,
    String label = '',
  }) {
    return using((arena) {
      final entryPointPtr = (entryPoint ?? 'main').toNativeUtf8(
        allocator: arena,
      );
      final desc = arena<ffi.WGPUComputePipelineDescriptor>();

      desc.ref.layout = (layout as WgpuPipelineLayout?)?.handle ?? 0;
      desc.ref.module = (module as WgpuShaderModule).handle;
      desc.ref.entry_point = entryPointPtr.cast();
      if (label.isNotEmpty) {
        desc.ref.label = label.toNativeUtf8(allocator: arena).cast();
      }

      if (constants.isNotEmpty) {
        final keys = arena<Pointer<Char>>(constants.length);
        final values = arena<Double>(constants.length);
        var i = 0;
        for (final entry in constants.entries) {
          keys[i] = entry.key.toNativeUtf8(allocator: arena).cast();
          values[i] = entry.value;
          i++;
        }
        desc.ref.constant_count = constants.length;
        desc.ref.constant_keys = keys;
        desc.ref.constant_values = values;
      }

      final handle = ffi.wgpun_DeviceCreateComputePipeline(
        _handle,
        desc,
      );

      if (handle == 0) {
        throw StateError(
          'Failed to create compute pipeline: ${wgpuLastError()}',
        );
      }

      final errs = errors;
      if (errs.isNotEmpty) {
        throw StateError(
          'Compute pipeline validation failed:\n${errs.join('\n')}',
        );
      }

      return WgpuComputePipeline.internal(handle, label: label);
    });
  }

  /// Creates a render pipeline.
  @override
  WgpuRenderPipeline createRenderPipeline(
    GpuRenderPipelineDescriptor desc,
  ) {
    if (desc.vertexEntryPoint != null && desc.vertexEntryPoint!.isEmpty) {
      throw ArgumentError('vertexEntryPoint cannot be empty');
    }
    if (desc.fragmentModule != null &&
        (desc.fragmentEntryPoint == null || desc.fragmentEntryPoint!.isEmpty)) {
      throw ArgumentError(
        'fragmentEntryPoint is required when fragmentModule is provided',
      );
    }
    for (final layout in desc.vertexBuffers) {
      if (layout == null) continue;
      if (layout.arrayStride <= 0) {
        throw ArgumentError('arrayStride must be positive');
      }
      if (layout.attributes.isEmpty) {
        throw ArgumentError(
          'vertex buffer layout must have at least one attribute',
        );
      }
    }
    if (desc.multisampleCount < 1) {
      throw ArgumentError('multisampleCount must be at least 1');
    }

    return using((arena) {
      final vertexEntryPointPtr = (desc.vertexEntryPoint ?? 'main')
          .toNativeUtf8(allocator: arena);

      Pointer<Utf8> fragmentEntryPointPtr = nullptr;
      if (desc.fragmentEntryPoint != null) {
        fragmentEntryPointPtr = desc.fragmentEntryPoint!.toNativeUtf8(
          allocator: arena,
        );
      }

      final bufferLayoutsPtr = arena<ffi.WGPUVertexBufferLayout>(
        desc.vertexBuffers.isEmpty ? 1 : desc.vertexBuffers.length,
      );

      for (var i = 0; i < desc.vertexBuffers.length; i++) {
        final layout = desc.vertexBuffers[i];
        if (layout == null) {
          bufferLayoutsPtr[i].array_stride = 0;
          bufferLayoutsPtr[i].attribute_count = 0;
          continue;
        }
        final attrsPtr = arena<ffi.WGPUVertexAttribute>(
          layout.attributes.length,
        );

        for (var j = 0; j < layout.attributes.length; j++) {
          final attr = layout.attributes[j];
          attrsPtr[j].format = attr.format.ffiValue;
          attrsPtr[j].offset = attr.offset;
          attrsPtr[j].shader_location = attr.shaderLocation;
        }

        bufferLayoutsPtr[i].array_stride = layout.arrayStride;
        bufferLayoutsPtr[i].step_mode = layout.stepMode.ffiValue;
        bufferLayoutsPtr[i].attributes = attrsPtr;
        bufferLayoutsPtr[i].attribute_count = layout.attributes.length;
      }

      final colorTargetsPtr = arena<ffi.WGPUColorTargetState>(
        desc.colorTargets.isEmpty ? 1 : desc.colorTargets.length,
      );

      for (var i = 0; i < desc.colorTargets.length; i++) {
        final target = desc.colorTargets[i];
        if (target == null) {
          colorTargetsPtr[i].write_mask = 0;
          colorTargetsPtr[i].blend_enabled = 0;
          continue;
        }
        colorTargetsPtr[i].format = target.format.ffiValue;
        colorTargetsPtr[i].write_mask = target.writeMask;

        if (target.blend != null) {
          colorTargetsPtr[i].blend_enabled = 1;
          colorTargetsPtr[i].blend_color.operation =
              target.blend!.color.operation.ffiValue;
          colorTargetsPtr[i].blend_color.src_factor =
              target.blend!.color.srcFactor.ffiValue;
          colorTargetsPtr[i].blend_color.dst_factor =
              target.blend!.color.dstFactor.ffiValue;
          colorTargetsPtr[i].blend_alpha.operation =
              target.blend!.alpha.operation.ffiValue;
          colorTargetsPtr[i].blend_alpha.src_factor =
              target.blend!.alpha.srcFactor.ffiValue;
          colorTargetsPtr[i].blend_alpha.dst_factor =
              target.blend!.alpha.dstFactor.ffiValue;
        } else {
          colorTargetsPtr[i].blend_enabled = 0;
        }
      }

      final pipelineDesc = arena<ffi.WGPURenderPipelineDescriptor>();
      pipelineDesc.ref.layout =
          (desc.layout as WgpuPipelineLayout?)?.handle ?? 0;
      if (desc.label.isNotEmpty) {
        pipelineDesc.ref.label = desc.label
            .toNativeUtf8(allocator: arena)
            .cast();
      }

      pipelineDesc.ref.vertex.module =
          (desc.vertexModule as WgpuShaderModule).handle;
      pipelineDesc.ref.vertex.entry_point = vertexEntryPointPtr.cast();
      pipelineDesc.ref.vertex.buffers = bufferLayoutsPtr;
      pipelineDesc.ref.vertex.buffer_count = desc.vertexBuffers.length;

      if (desc.vertexConstants.isNotEmpty) {
        final keys = arena<Pointer<Char>>(desc.vertexConstants.length);
        final values = arena<Double>(desc.vertexConstants.length);
        var i = 0;
        for (final entry in desc.vertexConstants.entries) {
          keys[i] = entry.key.toNativeUtf8(allocator: arena).cast();
          values[i] = entry.value;
          i++;
        }
        pipelineDesc.ref.vertex.constant_count = desc.vertexConstants.length;
        pipelineDesc.ref.vertex.constant_keys = keys;
        pipelineDesc.ref.vertex.constant_values = values;
      }

      if (desc.fragmentModule != null) {
        pipelineDesc.ref.fragment.module =
            (desc.fragmentModule! as WgpuShaderModule).handle;
        pipelineDesc.ref.fragment.entry_point = fragmentEntryPointPtr.cast();
        pipelineDesc.ref.fragment.targets = colorTargetsPtr;
        pipelineDesc.ref.fragment.target_count = desc.colorTargets.length;

        if (desc.fragmentConstants.isNotEmpty) {
          final keys = arena<Pointer<Char>>(desc.fragmentConstants.length);
          final values = arena<Double>(desc.fragmentConstants.length);
          var i = 0;
          for (final entry in desc.fragmentConstants.entries) {
            keys[i] = entry.key.toNativeUtf8(allocator: arena).cast();
            values[i] = entry.value;
            i++;
          }
          pipelineDesc.ref.fragment.constant_count =
              desc.fragmentConstants.length;
          pipelineDesc.ref.fragment.constant_keys = keys;
          pipelineDesc.ref.fragment.constant_values = values;
        }
      }

      pipelineDesc.ref.primitive_topology = desc.primitiveTopology.ffiValue;
      pipelineDesc.ref.strip_index_format =
          desc.stripIndexFormat?.ffiValue ?? 0xFFFFFFFF;
      pipelineDesc.ref.front_face = desc.frontFace.ffiValue;
      pipelineDesc.ref.cull_mode = desc.cullMode.ffiValue;
      pipelineDesc.ref.unclipped_depth = desc.unclippedDepth ? 1 : 0;

      if (desc.depthStencil != null) {
        pipelineDesc.ref.depth_stencil_enabled = 1;
        pipelineDesc.ref.depth_stencil.format =
            desc.depthStencil!.format.ffiValue;
        pipelineDesc.ref.depth_stencil.depth_write_enabled =
            (desc.depthStencil!.depthWriteEnabled ?? false) ? 1 : 0;
        pipelineDesc.ref.depth_stencil.depth_compare =
            (desc.depthStencil!.depthCompare ?? GpuCompareFunction.always)
                .ffiValue;
        pipelineDesc.ref.depth_stencil.depth_bias =
            desc.depthStencil!.depthBias;
        pipelineDesc.ref.depth_stencil.depth_bias_slope_scale =
            desc.depthStencil!.depthBiasSlopeScale;
        pipelineDesc.ref.depth_stencil.depth_bias_clamp =
            desc.depthStencil!.depthBiasClamp;
        // wgpu rejects stencil state on formats without a stencil aspect.
        // For depth-only formats, leave stencil fields at 0 (arena-zeroed).
        // The Rust FFI layer treats 0 as sentinels for wgpu defaults
        // (compare→Always, ops→Keep, masks→0xFFFFFFFF), producing a
        // disabled StencilState that passes validation.
        final hasStencil = switch (desc.depthStencil!.format) {
          GpuTextureFormat.stencil8 ||
          GpuTextureFormat.depth24PlusStencil8 ||
          GpuTextureFormat.depth32FloatStencil8 => true,
          _ => false,
        };
        if (hasStencil) {
          pipelineDesc.ref.depth_stencil.stencil_front_compare =
              desc.depthStencil!.stencilFront.compare.ffiValue;
          pipelineDesc.ref.depth_stencil.stencil_front_fail_op =
              desc.depthStencil!.stencilFront.failOp.ffiValue;
          pipelineDesc.ref.depth_stencil.stencil_front_depth_fail_op =
              desc.depthStencil!.stencilFront.depthFailOp.ffiValue;
          pipelineDesc.ref.depth_stencil.stencil_front_pass_op =
              desc.depthStencil!.stencilFront.passOp.ffiValue;
          pipelineDesc.ref.depth_stencil.stencil_back_compare =
              desc.depthStencil!.stencilBack.compare.ffiValue;
          pipelineDesc.ref.depth_stencil.stencil_back_fail_op =
              desc.depthStencil!.stencilBack.failOp.ffiValue;
          pipelineDesc.ref.depth_stencil.stencil_back_depth_fail_op =
              desc.depthStencil!.stencilBack.depthFailOp.ffiValue;
          pipelineDesc.ref.depth_stencil.stencil_back_pass_op =
              desc.depthStencil!.stencilBack.passOp.ffiValue;
          pipelineDesc.ref.depth_stencil.stencil_read_mask =
              desc.depthStencil!.stencilReadMask;
          pipelineDesc.ref.depth_stencil.stencil_write_mask =
              desc.depthStencil!.stencilWriteMask;
        }
      } else {
        pipelineDesc.ref.depth_stencil_enabled = 0;
      }

      pipelineDesc.ref.multisample_count = desc.multisampleCount;
      pipelineDesc.ref.multisample_mask = desc.multisampleMask;
      pipelineDesc.ref.alpha_to_coverage_enabled = desc.alphaToCoverageEnabled
          ? 1
          : 0;

      final handle = ffi.wgpun_DeviceCreateRenderPipeline(
        _handle,
        pipelineDesc,
      );

      if (handle == 0) {
        throw StateError(
          'Failed to create render pipeline: ${wgpuLastError()}',
        );
      }

      final errs = errors;
      if (errs.isNotEmpty) {
        throw StateError(
          'Render pipeline validation failed:\n${errs.join('\n')}',
        );
      }

      return WgpuRenderPipeline.internal(handle, label: desc.label);
    });
  }

  @override
  Future<WgpuComputePipeline> createComputePipelineAsync({
    required GpuShaderModule module,
    String? entryPoint,
    Map<String, double> constants = const {},
    required GpuPipelineLayout? layout,
    String label = '',
  }) async {
    // wgpu doesn't expose async pipeline creation yet.
    // Fall back to synchronous creation.
    return createComputePipeline(
      module: module,
      entryPoint: entryPoint,
      constants: constants,
      layout: layout,
      label: label,
    );
  }

  @override
  Future<WgpuRenderPipeline> createRenderPipelineAsync(
    GpuRenderPipelineDescriptor descriptor,
  ) async {
    // wgpu doesn't expose async pipeline creation yet.
    // Fall back to synchronous creation.
    return createRenderPipeline(descriptor);
  }

  @override
  Future<GpuDeviceLostInfo> get lost => _lostCompleter.future;
  final _lostCompleter = Completer<GpuDeviceLostInfo>();

  @override
  Stream<GpuError> get onUncapturedError => _uncapturedErrorController.stream;
  final _uncapturedErrorController = StreamController<GpuError>.broadcast();

  @override
  void pushErrorScope(GpuErrorFilter filter) {
    final ffiFilter = switch (filter) {
      GpuErrorFilter.validation => 1,
      GpuErrorFilter.outOfMemory => 2,
      GpuErrorFilter.internal => 3,
    };
    ffi.wgpun_DevicePushErrorScope(_handle, ffiFilter);
  }

  @override
  Future<GpuError?> popErrorScope() async {
    final errorType = ffi.wgpun_DevicePopErrorScope(_handle);
    if (errorType == 0) return null;
    final message = wgpuLastError() ?? 'Unknown error';
    return switch (errorType) {
      1 => GpuValidationError(message),
      2 => GpuOutOfMemoryError(message),
      3 => GpuInternalError(message),
      _ => GpuValidationError(message),
    };
  }
}
