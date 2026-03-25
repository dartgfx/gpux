import 'dart:ffi';

import 'ffi/bindings_generated.dart' as ffi;
import 'resource.dart';

/// Handle for tracking GPU work completion.
///
/// Usage in game loop:
/// ```dart
/// final fence = queue.submitFenced(commands);
/// // ... each frame:
/// device.poll();
/// if (fence.isSignaled) {
///   // GPU finished this batch
///   fence.dispose();
/// }
/// ```
class WgpuFence extends WgpuNativeResource {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_FenceRelease_p,
    ),
  );

  final int _deviceHandle;

  WgpuFence.internal(int handle, this._deviceHandle) : super(handle, _fin);

  int get handle => nativeHandle;

  @override
  NativeFinalizer get finalizer => _fin;
  @override
  void release(int handle) => ffi.wgpun_FenceRelease(handle);

  /// Whether the GPU has completed work up to this fence.
  bool get isSignaled {
    if (isDisposed) return true;
    return ffi.wgpun_FenceStatus(_deviceHandle, nativeHandle) == 1;
  }

  /// Block until the GPU has completed work up to this fence.
  int wait() {
    if (isDisposed) return 0;
    return ffi.wgpun_FenceWait(_deviceHandle, nativeHandle);
  }
}
