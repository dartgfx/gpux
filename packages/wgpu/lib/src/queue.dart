import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:gpuweb/gpuweb.dart';

import 'ffi/bindings_generated.dart' as ffi;
import 'ffi/enum_ffi.dart';
import 'buffer.dart';
import 'encoder.dart';
import 'fence.dart';
import 'texture.dart';
import 'device.dart';

/// Marshals a list of command buffers to native handles.
Pointer<Uint64> _marshalCommandBuffers(
  Arena arena,
  List<GpuCommandBuffer> commandBuffers,
) {
  final buffers = arena<Uint64>(commandBuffers.length);
  for (var i = 0; i < commandBuffers.length; i++) {
    buffers[i] = (commandBuffers[i] as WgpuCommandBuffer).handle;
  }
  return buffers;
}

/// Copies a Uint8List to native memory.
Pointer<Uint8> _copyToNative(Arena arena, Uint8List data) {
  final ptr = arena<Uint8>(data.length);
  ptr.asTypedList(data.length).setAll(0, data);
  return ptr;
}

/// Command queue for submitting GPU work.
///
/// Access from a device:
/// ```dart
/// final device = adapter.requestDevice();
/// final queue = device.queue;
/// queue.submit([commandBuffer]);
/// queue.writeBuffer(buffer, data);
/// ```
class WgpuQueue implements GpuQueue {
  @override
  String label;
  final int _handle;

  /// The device handle this queue belongs to.
  /// Needed for fence operations that require the device.
  final int _deviceHandle;

  /// The device this queue belongs to.
  /// Retained to prevent garbage collection - queue must not outlive device.
  // ignore: unused_field
  final WgpuDevice? _device;

  /// Create a queue from a native handle.
  ///
  /// [device] is retained to prevent garbage collection.
  /// [deviceHandle] is the device handle for fence operations.
  WgpuQueue.fromHandle(
    int handle, {
    WgpuDevice? device,
    int deviceHandle = 0,
    this.label = '',
  }) : _handle = handle,
       _deviceHandle = device?.handle ?? deviceHandle,
       _device = device;

  /// The native handle.
  int get handle => _handle;

  /// Submits command buffers for execution.
  ///
  /// Empty list is a no-op (unlike [submitFenced] which throws).
  @override
  void submit(List<GpuCommandBuffer> commandBuffers) {
    if (commandBuffers.isEmpty) return;

    using((arena) {
      final buffers = _marshalCommandBuffers(arena, commandBuffers);
      ffi.wgpun_QueueSubmit(
        _handle,
        buffers,
        commandBuffers.length,
      );
    });
  }

  @override
  Future<void> onSubmittedWorkDone() async {
    ffi.wgpun_DevicePoll(_deviceHandle, 1);
  }

  /// Submits command buffers with fence. Returns handle to track completion.
  ///
  /// Use for manual control in game loops:
  /// ```dart
  /// final fence = queue.submitFenced(commands);
  /// // ... each frame:
  /// device.poll();
  /// if (fence.isSignaled) {
  ///   // GPU finished this batch
  ///   fence.dispose();
  /// }
  /// ```
  WgpuFence submitFenced(List<WgpuCommandBuffer> commandBuffers) {
    if (commandBuffers.isEmpty) {
      throw ArgumentError('commandBuffers cannot be empty');
    }

    return using((arena) {
      final buffers = _marshalCommandBuffers(arena, commandBuffers);

      final handle = ffi.wgpun_QueueSubmitFenced(
        _handle,
        buffers,
        commandBuffers.length,
      );

      if (handle == 0) {
        throw StateError('Failed to submit with fence');
      }

      return WgpuFence.internal(handle, _deviceHandle);
    });
  }

  /// Submits command buffers async. Returns Future that completes when GPU done.
  ///
  /// [pollInterval] controls how often to check for completion (default 100μs).
  /// Lower values reduce latency but increase CPU usage.
  ///
  /// For timeout support, use Dart's built-in `.timeout()`:
  /// ```dart
  /// await queue.submitAsync(commands).timeout(Duration(seconds: 5));
  /// ```
  Future<void> submitAsync(
    List<WgpuCommandBuffer> commandBuffers, {
    Duration pollInterval = const Duration(microseconds: 100),
  }) async {
    final fence = submitFenced(commandBuffers);

    while (!fence.isSignaled) {
      ffi.wgpun_DevicePoll(_deviceHandle, 0);
      await Future<void>.delayed(pollInterval);
    }

    fence.dispose();
  }

  /// Writes data to a buffer.
  ///
  /// Throws [ArgumentError] if the write would exceed the buffer bounds.
  @override
  void writeBuffer(
    GpuBuffer buffer,
    Uint8List data, {
    int bufferOffset = 0,
    int dataOffset = 0,
    int? size,
  }) {
    final writeSize = size ?? (data.length - dataOffset);
    if (writeSize <= 0) return;
    if (bufferOffset < 0) {
      throw ArgumentError('bufferOffset must be non-negative');
    }
    if (dataOffset < 0 || dataOffset > data.length) {
      throw ArgumentError('dataOffset out of range');
    }
    if (bufferOffset + writeSize > buffer.size) {
      throw ArgumentError(
        'Write exceeds buffer bounds: offset=$bufferOffset + size=$writeSize > buffer.size=${buffer.size}',
      );
    }

    using((arena) {
      final slice = data.buffer.asUint8List(
        data.offsetInBytes + dataOffset,
        writeSize,
      );
      final dataPtr = _copyToNative(arena, slice);
      ffi.wgpun_QueueWriteBuffer(
        _handle,
        (buffer as WgpuBuffer).handle,
        bufferOffset,
        dataPtr,
        writeSize,
      );
    });
  }

  /// Writes typed data (Float32List, Int32List, etc.) to a buffer (wgpu extension).
  void writeBufferTyped<T extends TypedData>(
    GpuBuffer buffer,
    T data, {
    int bufferOffset = 0,
  }) {
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    writeBuffer(buffer, bytes, bufferOffset: bufferOffset);
  }

  /// Writes data to a texture.
  ///
  /// [originZ] is the starting array layer (for 2D array textures) or
  /// depth slice (for 3D textures).
  @override
  void writeTexture({
    required GpuTexture texture,
    required Uint8List data,
    required int bytesPerRow,
    required int width,
    int height = 1,
    int depthOrArrayLayers = 1,
    int mipLevel = 0,
    GpuTextureAspect aspect = GpuTextureAspect.all,
    int originX = 0,
    int originY = 0,
    int originZ = 0,
    int dataOffset = 0,
    int? rowsPerImage,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('width and height must be positive');
    }

    final writeData = dataOffset > 0
        ? data.buffer.asUint8List(data.offsetInBytes + dataOffset)
        : data;
    if (writeData.isEmpty) return;

    using((arena) {
      final dataPtr = _copyToNative(arena, writeData);
      ffi.wgpun_QueueWriteTexture(
        _handle,
        (texture as WgpuTexture).handle,
        dataPtr,
        writeData.length,
        bytesPerRow,
        width,
        height,
        depthOrArrayLayers,
        mipLevel,
        originX,
        originY,
        originZ,
        aspect.ffiValue,
        rowsPerImage ?? 0,
      );
    });
  }

  /// Writes data to a specific array layer (wgpu extension, convenience).
  ///
  /// Equivalent to [writeTexture] with `originZ: arrayLayer`.
  void writeTextureLayer({
    required GpuTexture texture,
    required Uint8List data,
    required int bytesPerRow,
    required int width,
    required int height,
    required int arrayLayer,
    int mipLevel = 0,
  }) {
    writeTexture(
      texture: texture,
      data: data,
      bytesPerRow: bytesPerRow,
      width: width,
      height: height,
      mipLevel: mipLevel,
      originZ: arrayLayer,
    );
  }

  /// Gets the timestamp period in nanoseconds per tick (wgpu extension).
  ///
  /// Multiply raw timestamp query values by this to convert to nanoseconds.
  /// Cache this value - it doesn't change for the lifetime of the device.
  double getTimestampPeriod() {
    return ffi.wgpun_QueueGetTimestampPeriod(_handle);
  }
}
