import 'dart:ffi';
import 'dart:typed_data';

import 'ffi/bindings_generated.dart' as ffi;
import 'resource.dart' show WgpuNativeResource;

/// Handle for an in-progress or completed buffer mapping.
///
/// Usage for reading (game loop):
/// ```dart
/// final mapping = buffer.mapRead();
/// // ... each frame:
/// device.poll();
/// if (mapping.isReady) {
///   final data = mapping.read();
///   mapping.dispose();
/// }
/// ```
///
/// Usage for writing (game loop):
/// ```dart
/// final mapping = buffer.mapWrite();
/// // ... each frame:
/// device.poll();
/// if (mapping.isReady) {
///   mapping.pointer.asTypedList(count).setAll(0, myData);
///   mapping.dispose();  // unmap, GPU can use buffer now
/// }
/// ```
class BufferMapping extends WgpuNativeResource {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_BufferMappingRelease_p,
    ),
  );

  final int _bufferHandle;
  final bool _isWrite;

  BufferMapping._(int handle, this._bufferHandle, this._isWrite)
    : super(handle, _fin);

  /// Creates a read mapping for the given buffer.
  factory BufferMapping.read(
    int deviceHandle,
    int bufferHandle, {
    int offset = 0,
    int? size,
  }) {
    final mappingSize = size ?? 0;
    final handle = ffi.wgpun_BufferMapStart(
      deviceHandle,
      bufferHandle,
      offset,
      mappingSize,
      0, // mode: read
    );
    if (handle == 0) {
      throw StateError('Failed to start buffer mapping');
    }
    return BufferMapping._(handle, bufferHandle, false);
  }

  /// Creates a write mapping for the given buffer.
  factory BufferMapping.write(
    int deviceHandle,
    int bufferHandle, {
    int offset = 0,
    int? size,
  }) {
    final mappingSize = size ?? 0;
    final handle = ffi.wgpun_BufferMapStart(
      deviceHandle,
      bufferHandle,
      offset,
      mappingSize,
      1, // mode: write
    );
    if (handle == 0) {
      throw StateError('Failed to start buffer mapping');
    }
    return BufferMapping._(handle, bufferHandle, true);
  }

  @override
  NativeFinalizer get finalizer => _fin;

  @override
  void release(int handle) {
    final originalBuffer = _isWrite ? _bufferHandle : 0;
    ffi.wgpun_BufferUnmap(handle, originalBuffer);
  }

  /// Whether this is a write mapping.
  bool get isWrite => _isWrite;

  /// Status of this mapping: 0=pending, 1=ready, 2+=error.
  int get status {
    if (isDisposed) return 2;
    return ffi.wgpun_BufferMapStatus(nativeHandle);
  }

  /// Whether the mapping is ready for access.
  bool get isReady => status == 1;

  /// Size of the mapped region in bytes.
  int get size {
    if (isDisposed) return 0;
    return ffi.wgpun_BufferMapGetSize(nativeHandle);
  }

  // ─────────────────────────────────────────────────────────────────
  // FOR READ MAPPINGS
  // ─────────────────────────────────────────────────────────────────

  /// Read the mapped data. Only call when [isReady] is true.
  Uint8List read() {
    _checkReadAccess();
    final ptr = ffi.wgpun_BufferMapGetPointer(nativeHandle);
    if (ptr == nullptr) {
      throw StateError('Failed to get mapped pointer');
    }
    final mappedSize = size;
    final result = Uint8List(mappedSize);
    result.setAll(0, ptr.asTypedList(mappedSize));
    return result;
  }

  /// Read as typed data. Only call when [isReady] is true.
  T readTyped<T extends TypedData>() {
    final bytes = read();
    return switch (T) {
      const (Float32List) => bytes.buffer.asFloat32List() as T,
      const (Int32List) => bytes.buffer.asInt32List() as T,
      const (Uint32List) => bytes.buffer.asUint32List() as T,
      const (Float64List) => bytes.buffer.asFloat64List() as T,
      const (Int16List) => bytes.buffer.asInt16List() as T,
      const (Uint16List) => bytes.buffer.asUint16List() as T,
      const (Int8List) => bytes.buffer.asInt8List() as T,
      const (Uint8List) => bytes as T,
      _ => throw ArgumentError('Unsupported type: $T'),
    };
  }

  void _checkReadAccess() {
    if (isDisposed) throw StateError('BufferMapping already disposed');
    if (_isWrite) throw StateError('Cannot read from a write mapping');
    if (!isReady) throw StateError('Mapping not ready');
  }

  // ─────────────────────────────────────────────────────────────────
  // FOR WRITE MAPPINGS
  // ─────────────────────────────────────────────────────────────────

  /// Get pointer to mapped memory for direct writes.
  ///
  /// Only valid until [dispose] is called.
  Pointer<Uint8> get pointer {
    _checkWriteAccess();
    final ptr = ffi.wgpun_BufferMapGetPointerMut(nativeHandle);
    if (ptr == nullptr) {
      throw StateError('Failed to get mapped pointer');
    }
    return ptr;
  }

  void _checkWriteAccess() {
    if (isDisposed) throw StateError('BufferMapping already disposed');
    if (!_isWrite) throw StateError('Cannot write to a read mapping');
    if (!isReady) throw StateError('Mapping not ready');
  }
}
