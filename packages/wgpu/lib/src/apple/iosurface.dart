import 'dart:ffi';

import '../../wgpu_ffi.dart' as wgpu_ffi;
import '../resource.dart';
import '../ffi/bindings_generated.dart' as ffi;

/// Retained Apple IOSurface handle.
///
/// This object owns a CoreFoundation retain on the IOSurface and releases it
/// when disposed or finalized.
final class WgpuAppleIOSurface implements WgpuResource, Finalizable {
  static final _finalizer = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_IOSurfaceRelease_p,
    ),
  );

  WgpuAppleIOSurface._(this.address) {
    _finalizer.attach(this, Pointer<Void>.fromAddress(address), detach: this);
  }

  /// Retains an existing IOSurface pointer address.
  factory WgpuAppleIOSurface.retainAddress(int address) {
    if (address == 0) {
      throw ArgumentError('address must not be 0');
    }
    final retained = wgpu_ffi.wgpun_IOSurfaceRetain(
      Pointer<Void>.fromAddress(address),
    );
    if (retained == nullptr) {
      throw StateError(
        'Failed to retain IOSurface: ${wgpu_ffi.wgpuLastError()}',
      );
    }
    return WgpuAppleIOSurface._(retained.address);
  }

  /// Retained IOSurface pointer address.
  final int address;
  var _disposed = false;

  Pointer<Void> get pointer {
    _throwIfDisposed();
    return Pointer<Void>.fromAddress(address);
  }

  /// Creates an independent retain for the same IOSurface.
  WgpuAppleIOSurface retain() {
    _throwIfDisposed();
    return WgpuAppleIOSurface.retainAddress(address);
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
    wgpu_ffi.wgpun_IOSurfaceRelease(Pointer<Void>.fromAddress(address));
  }

  void _throwIfDisposed() {
    if (_disposed) {
      throw StateError('WgpuAppleIOSurface used after dispose');
    }
  }
}
