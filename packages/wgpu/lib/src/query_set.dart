import 'dart:ffi';

import 'package:gpuweb/gpuweb.dart';
import 'ffi/bindings_generated.dart' as ffi;
import 'resource.dart';

/// A set of GPU timestamp queries for profiling.
class WgpuQuerySet extends WgpuNativeResource implements GpuQuerySet {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_QuerySetRelease_p,
    ),
  );

  @override
  String label;
  @override
  final GpuQueryType type;
  @override
  final int count;

  WgpuQuerySet.internal(int handle, this.type, this.count, {this.label = ''})
    : super(handle, _fin);

  int get handle => nativeHandle;

  @override
  NativeFinalizer get finalizer => _fin;
  @override
  void release(int handle) => ffi.wgpun_QuerySetRelease(handle);

  @override
  void destroy() => dispose();
}
