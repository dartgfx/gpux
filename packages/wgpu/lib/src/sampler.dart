import 'dart:ffi';

import 'package:gpuweb/gpuweb.dart';

import 'ffi/bindings_generated.dart' as ffi;
import 'resource.dart';

/// A texture sampler.
class WgpuSampler extends WgpuNativeResource implements GpuSampler {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_SamplerRelease_p,
    ),
  );

  @override
  String label;

  WgpuSampler.internal(int handle, {this.label = ''}) : super(handle, _fin);

  int get handle => nativeHandle;

  @override
  NativeFinalizer get finalizer => _fin;
  @override
  void release(int handle) => ffi.wgpun_SamplerRelease(handle);
}
