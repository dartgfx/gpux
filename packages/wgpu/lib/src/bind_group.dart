import 'dart:ffi';

import 'package:gpuweb/gpuweb.dart';

import 'ffi/bindings_generated.dart' as ffi;
import 'resource.dart';

/// Bind group entry for an array of texture views (wgpu extension, not WebGPU spec).
class WgpuTextureViewArrayBinding extends GpuBindGroupEntry {
  @override
  final int binding;
  final List<GpuTextureView> views;

  WgpuTextureViewArrayBinding({required this.binding, required this.views});
}

/// A bind group layout that describes bindings.
class WgpuBindGroupLayout extends WgpuNativeResource
    implements GpuBindGroupLayout {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_BindGroupLayoutRelease_p,
    ),
  );

  @override
  String label;

  WgpuBindGroupLayout.internal(int handle, {this.label = ''})
    : super(handle, _fin);

  int get handle => nativeHandle;

  @override
  NativeFinalizer get finalizer => _fin;
  @override
  void release(int handle) => ffi.wgpun_BindGroupLayoutRelease(handle);
}

/// A bind group that binds resources to shader bindings.
class WgpuBindGroup extends WgpuNativeResource implements GpuBindGroup {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_BindGroupRelease_p,
    ),
  );

  @override
  String label;

  WgpuBindGroup.internal(int handle, {this.label = ''}) : super(handle, _fin);

  int get handle => nativeHandle;

  @override
  NativeFinalizer get finalizer => _fin;
  @override
  void release(int handle) => ffi.wgpun_BindGroupRelease(handle);
}
