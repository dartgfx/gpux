import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:gpuweb/gpuweb.dart';
import '../wgpu_ffi.dart' show wgpuLastError;
import 'ffi/bindings_generated.dart' as ffi;
import 'resource.dart';
import 'buffer_mapping.dart';

/// A GPU buffer for storing vertex, index, uniform, or storage data.
class WgpuBuffer extends WgpuNativeResource implements GpuBuffer {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_BufferRelease_p,
    ),
  );

  @override
  String label;
  final int _deviceHandle;
  final int _size;
  final GpuBufferUsageFlags _usage;

  // Mapping state
  int? _mappingHandle;
  GpuMapModeFlags? _mapMode;

  WgpuBuffer.internal(
    int handle,
    this._deviceHandle,
    this._size,
    this._usage, {
    this.label = '',
  }) : super(handle, _fin);

  int get handle => nativeHandle;

  @override
  NativeFinalizer get finalizer => _fin;
  @override
  void release(int handle) => ffi.wgpun_BufferRelease(handle);

  /// Size in bytes.
  @override
  int get size => _size;

  /// Buffer usage flags.
  @override
  GpuBufferUsageFlags get usage => _usage;

  void _checkNotDisposed() {
    if (isDisposed) throw StateError('Buffer already disposed');
  }

  // ─────────────────────────────────────────────────────────────────
  // SPEC: mapState / mapAsync / getMappedRange / unmap
  // ─────────────────────────────────────────────────────────────────

  @override
  GpuBufferMapState get mapState {
    if (isDisposed) return GpuBufferMapState.unmapped;
    if (_mappingHandle == null) return GpuBufferMapState.unmapped;
    final s = ffi.wgpun_BufferMapStatus(_mappingHandle!);
    return s == 1 ? GpuBufferMapState.mapped : GpuBufferMapState.pending;
  }

  @override
  Future<void> mapAsync(
    GpuMapModeFlags mode, {
    int offset = 0,
    int? size,
  }) async {
    _checkNotDisposed();
    final mappingSize = size ?? 0; // 0 = entire buffer on Rust side
    final ffiMode = mode == GpuMapMode.read ? 0 : 1;
    final h = ffi.wgpun_BufferMapStart(
      _deviceHandle,
      nativeHandle,
      offset,
      mappingSize,
      ffiMode,
    );
    if (h == 0) throw StateError('Failed to start buffer mapping');
    _mappingHandle = h;
    _mapMode = mode;

    while (mapState == GpuBufferMapState.pending) {
      if (isDisposed) throw StateError('Buffer disposed during mapAsync');
      ffi.wgpun_DevicePoll(_deviceHandle, 0);
      await Future<void>.delayed(const Duration(microseconds: 100));
    }
  }

  @override
  ByteBuffer getMappedRange({int offset = 0, int? size}) {
    _checkNotDisposed();
    if (_mappingHandle == null || mapState != GpuBufferMapState.mapped) {
      throw StateError('Buffer is not mapped');
    }
    final ptr = _mapMode == GpuMapMode.read
        ? ffi.wgpun_BufferMapGetPointer(_mappingHandle!)
        : ffi.wgpun_BufferMapGetPointerMut(_mappingHandle!);
    if (ptr == nullptr) throw StateError('Failed to get mapped pointer');
    final mappedSize = size ?? ffi.wgpun_BufferMapGetSize(_mappingHandle!);
    final result = Uint8List(mappedSize);
    result.setAll(0, ptr.asTypedList(mappedSize));
    return result.buffer;
  }

  @override
  void unmap() {
    if (isDisposed) return;
    if (_mappingHandle == null) return;
    final originalBuffer = (_mapMode == GpuMapMode.write) ? nativeHandle : 0;
    ffi.wgpun_BufferUnmap(_mappingHandle!, originalBuffer);
    _mappingHandle = null;
    _mapMode = null;
  }

  // ─────────────────────────────────────────────────────────────────
  // WGPU-SPECIFIC: readSync / readAsync / mapRead / mapWrite
  // ─────────────────────────────────────────────────────────────────

  /// Reads data from this buffer synchronously (wgpu only).
  Uint8List readSync({int offset = 0, int? size}) {
    _checkNotDisposed();
    final readSize = size ?? (_size - offset);
    if (readSize <= 0) {
      throw ArgumentError('Invalid read size: $readSize');
    }

    final outputPtr = calloc<Uint8>(readSize);

    final bytesRead = ffi.wgpun_BufferReadSync(
      _deviceHandle,
      nativeHandle,
      offset,
      readSize,
      outputPtr,
    );

    if (bytesRead == 0) {
      calloc.free(outputPtr);
      throw StateError('Failed to read buffer: ${wgpuLastError()}');
    }

    final result = Uint8List(bytesRead);
    result.setAll(0, outputPtr.asTypedList(bytesRead));
    calloc.free(outputPtr);

    return result;
  }

  /// Async read (wgpu only). Returns Future that completes when data ready.
  Future<Uint8List> readAsync({
    int offset = 0,
    int? size,
    Duration pollInterval = const Duration(microseconds: 100),
  }) async {
    _checkNotDisposed();
    final mapping = mapRead(offset: offset, size: size);

    while (!mapping.isReady) {
      if (isDisposed) {
        mapping.dispose();
        throw StateError('Buffer disposed during readAsync');
      }
      ffi.wgpun_DevicePoll(_deviceHandle, 0);
      await Future<void>.delayed(pollInterval);
    }

    final data = mapping.read();
    mapping.dispose();
    return data;
  }

  /// Start async map for reading (wgpu only).
  BufferMapping mapRead({int offset = 0, int? size}) {
    _checkNotDisposed();
    return BufferMapping.read(
      _deviceHandle,
      nativeHandle,
      offset: offset,
      size: size ?? _size,
    );
  }

  /// Start async map for writing (wgpu only).
  BufferMapping mapWrite({int offset = 0, int? size}) {
    _checkNotDisposed();
    return BufferMapping.write(
      _deviceHandle,
      nativeHandle,
      offset: offset,
      size: size ?? _size,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    if (isDisposed) return;
    if (_mappingHandle != null) unmap();
    super.dispose();
  }

  @override
  void destroy() => dispose();
}
