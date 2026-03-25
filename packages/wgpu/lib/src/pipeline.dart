import 'dart:ffi';

import 'package:gpuweb/gpuweb.dart';

import 'ffi/bindings_generated.dart' as ffi;
import 'resource.dart';
import 'bind_group.dart';

/// A pipeline layout that groups bind group layouts.
class WgpuPipelineLayout extends WgpuNativeResource
    implements GpuPipelineLayout {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_PipelineLayoutRelease_p,
    ),
  );

  @override
  String label;

  WgpuPipelineLayout.internal(int handle, {this.label = ''})
    : super(handle, _fin);

  int get handle => nativeHandle;

  @override
  NativeFinalizer get finalizer => _fin;
  @override
  void release(int handle) => ffi.wgpun_PipelineLayoutRelease(handle);
}

/// A render pipeline.
class WgpuRenderPipeline extends WgpuNativeResource
    implements GpuRenderPipeline {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_RenderPipelineRelease_p,
    ),
  );

  @override
  String label;

  WgpuRenderPipeline.internal(int handle, {this.label = ''})
    : super(handle, _fin);

  int get handle => nativeHandle;

  @override
  NativeFinalizer get finalizer => _fin;
  @override
  void release(int handle) => ffi.wgpun_RenderPipelineRelease(handle);

  @override
  WgpuBindGroupLayout getBindGroupLayout(int index) {
    final layoutHandle = ffi.wgpun_RenderPipelineGetBindGroupLayout(
      nativeHandle,
      index,
    );
    if (layoutHandle == 0) {
      throw StateError(
        'Failed to get bind group layout at index $index',
      );
    }
    return WgpuBindGroupLayout.internal(layoutHandle);
  }
}

/// A compute pipeline.
class WgpuComputePipeline extends WgpuNativeResource
    implements GpuComputePipeline {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_ComputePipelineRelease_p,
    ),
  );

  @override
  String label;

  WgpuComputePipeline.internal(int handle, {this.label = ''})
    : super(handle, _fin);

  int get handle => nativeHandle;

  @override
  NativeFinalizer get finalizer => _fin;
  @override
  void release(int handle) => ffi.wgpun_ComputePipelineRelease(handle);

  @override
  WgpuBindGroupLayout getBindGroupLayout(int index) {
    final layoutHandle = ffi.wgpun_ComputePipelineGetBindGroupLayout(
      nativeHandle,
      index,
    );
    if (layoutHandle == 0) {
      throw StateError(
        'Failed to get bind group layout at index $index',
      );
    }
    return WgpuBindGroupLayout.internal(layoutHandle);
  }
}
