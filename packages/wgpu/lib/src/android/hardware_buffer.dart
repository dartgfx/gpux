import 'dart:ffi';

import '../../wgpu_ffi.dart' as wgpu_ffi;
import '../resource.dart';
import '../ffi/bindings_generated.dart' as ffi;

/// Retained Android AHardwareBuffer handle.
///
/// This object owns a reference on the AHardwareBuffer (via
/// `AHardwareBuffer_acquire`) and releases it when disposed or finalized.
final class WgpuAndroidHardwareBuffer implements WgpuResource, Finalizable {
  static final _finalizer = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_AHardwareBufferRelease_p,
    ),
  );

  WgpuAndroidHardwareBuffer._(this.address) {
    _finalizer.attach(this, Pointer<Void>.fromAddress(address), detach: this);
  }

  /// Acquires an additional reference on an existing AHardwareBuffer pointer.
  factory WgpuAndroidHardwareBuffer.acquireAddress(int address) {
    if (address == 0) {
      throw ArgumentError('address must not be 0');
    }
    final acquired = wgpu_ffi.wgpun_AHardwareBufferAcquire(
      Pointer<Void>.fromAddress(address),
    );
    if (acquired == nullptr) {
      throw StateError(
        'Failed to acquire AHardwareBuffer: ${wgpu_ffi.wgpuLastError()}',
      );
    }
    return WgpuAndroidHardwareBuffer._(acquired.address);
  }

  /// Retained AHardwareBuffer pointer address.
  final int address;
  var _disposed = false;

  Pointer<Void> get pointer {
    _throwIfDisposed();
    return Pointer<Void>.fromAddress(address);
  }

  /// Creates an independent acquire for the same AHardwareBuffer.
  WgpuAndroidHardwareBuffer acquire() {
    _throwIfDisposed();
    return WgpuAndroidHardwareBuffer.acquireAddress(address);
  }

  @override
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _finalizer.detach(this);
    wgpu_ffi.wgpun_AHardwareBufferRelease(Pointer<Void>.fromAddress(address));
  }

  void _throwIfDisposed() {
    if (_disposed) {
      throw StateError('WgpuAndroidHardwareBuffer used after dispose');
    }
  }
}
