import 'dart:ffi';

/// Base interface for GPU resources that require explicit cleanup.
abstract interface class WgpuResource {
  /// Whether this resource has been disposed.
  bool get isDisposed;

  /// Release native resources. Safe to call multiple times.
  void dispose();

  /// Disposes all resources in reverse order (LIFO).
  static void disposeAll(List<WgpuResource> resources) {
    for (var i = resources.length - 1; i >= 0; i--) {
      resources[i].dispose();
    }
  }
}

/// Base class for GPU resources backed by a native handle with automatic
/// cleanup via [NativeFinalizer].
///
/// For extra cleanup before release, override [dispose] and call `super.dispose()` last.
abstract class WgpuNativeResource implements WgpuResource, Finalizable {
  /// The native handle value (opaque u64 from Rust).
  final int _nativeHandle;
  bool _disposed = false;

  WgpuNativeResource(this._nativeHandle, NativeFinalizer finalizer) {
    finalizer.attach(this, Pointer.fromAddress(_nativeHandle), detach: this);
  }

  /// The native handle. Throws if accessed after dispose.
  int get nativeHandle {
    if (_disposed) {
      throw StateError(
        '$runtimeType used after dispose (handle=0x${_nativeHandle.toRadixString(16)})',
      );
    }
    return _nativeHandle;
  }

  @override
  bool get isDisposed => _disposed;

  /// The static [NativeFinalizer] for this resource type (for detach on dispose).
  NativeFinalizer get finalizer;

  /// Release the native resource by calling the FFI release function.
  void release(int handle);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    finalizer.detach(this);
    release(_nativeHandle);
  }
}
