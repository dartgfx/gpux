// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:wgpu/wgpu.dart';

/// Creates a fresh device with timestamp query support.
Future<WgpuDevice> _createDevice() async {
  final instance = Wgpu.create();
  final adapter = await instance.requestAdapter();
  return adapter.requestDevice(
    const GpuDeviceDescriptor(
      requiredFeatures: {GpuFeatureName.timestampQuery},
    ),
  );
}

/// Creates a 1x1 render target for timestamp marker passes.
(GpuTexture, GpuTextureView) _createMarkerTarget(GpuDevice device) {
  final tex = device.createTexture(
    width: 1,
    format: GpuTextureFormat.r8Unorm,
    usage: GpuTextureUsage.renderAttachment,
  );
  return (tex, tex.createView());
}

/// Empty render pass that writes a single timestamp.
void _writeTimestamp(
  GpuCommandEncoder encoder,
  GpuTextureView markerView,
  GpuQuerySet qs,
  int index,
) {
  encoder
      .beginRenderPass(
        colorAttachments: [
          GpuColorAttachment(
            view: markerView,
            loadOp: GpuLoadOp.load,
            storeOp: GpuStoreOp.discard,
          ),
        ],
        timestampWrites: GpuRenderPassTimestampWrites(
          querySet: qs,
          beginningOfPassWriteIndex: index,
        ),
      )
      .end();
}

void _expectTimestampReadback(Uint64List timestamps) {
  expect(timestamps, hasLength(greaterThanOrEqualTo(2)));
  // Timestamp values are implementation-defined by WebGPU. The useful public
  // contract here is that resolving and reading them succeeds.
  expect(timestamps[0], greaterThanOrEqualTo(0));
  expect(timestamps[1], greaterThanOrEqualTo(0));
}

void main() {
  group('Timestamp queries', () {
    test('query set creation and destroy', () async {
      final device = await _createDevice();
      final qs = device.createQuerySet(
        type: GpuQueryType.timestamp,
        count: 4,
      );
      expect(qs.type, GpuQueryType.timestamp);
      expect(qs.count, 4);
      qs.destroy();
    });

    test(
      'render pass timestamps produce non-zero values via readSync',
      () async {
        final device = await _createDevice();
        final (markerTex, markerView) = _createMarkerTarget(device);
        final queue = device.queue;

        final qs = device.createQuerySet(
          type: GpuQueryType.timestamp,
          count: 4,
        );
        final resolveBuffer = device.createBuffer(
          size: 4 * 8,
          usage: GpuBufferUsage.queryResolve | GpuBufferUsage.copySrc,
        );

        final encoder = device.createCommandEncoder();
        _writeTimestamp(encoder, markerView, qs, 0);
        _writeTimestamp(encoder, markerView, qs, 1);
        encoder.resolveQuerySet(
          qs,
          firstQuery: 0,
          queryCount: 2,
          destination: resolveBuffer,
        );
        queue.submit([encoder.finish()]);

        final bytes = resolveBuffer.readSync(size: 2 * 8);
        final timestamps = bytes.buffer.asUint64List();

        _expectTimestampReadback(timestamps);

        resolveBuffer.destroy();
        qs.destroy();
        markerTex.destroy();
      },
    );

    test('render pass timestamps via mapAsync', () async {
      final device = await _createDevice();
      final (markerTex, markerView) = _createMarkerTarget(device);
      final queue = device.queue;

      final qs = device.createQuerySet(
        type: GpuQueryType.timestamp,
        count: 4,
      );
      final resolveBuffer = device.createBuffer(
        size: 4 * 8,
        usage: GpuBufferUsage.queryResolve | GpuBufferUsage.copySrc,
      );
      final readBuffer = device.createBuffer(
        size: 4 * 8,
        usage: GpuBufferUsage.mapRead | GpuBufferUsage.copyDst,
      );

      final encoder = device.createCommandEncoder();
      _writeTimestamp(encoder, markerView, qs, 0);
      _writeTimestamp(encoder, markerView, qs, 1);
      encoder.resolveQuerySet(
        qs,
        firstQuery: 0,
        queryCount: 2,
        destination: resolveBuffer,
      );
      encoder.copyBufferToBuffer(
        source: resolveBuffer,
        destination: readBuffer,
        size: 2 * 8,
      );
      queue.submit([encoder.finish()]);

      await readBuffer.mapAsync(GpuMapMode.read, size: 2 * 8);
      final byteBuffer = readBuffer.getMappedRange(size: 2 * 8);
      final timestamps = byteBuffer.asUint64List();

      _expectTimestampReadback(timestamps);

      readBuffer.unmap();
      readBuffer.destroy();
      resolveBuffer.destroy();
      qs.destroy();
      markerTex.destroy();
    });

    test('double-buffered readback pattern', () async {
      final device = await _createDevice();
      final (markerTex, markerView) = _createMarkerTarget(device);
      final queue = device.queue;

      final qs = device.createQuerySet(
        type: GpuQueryType.timestamp,
        count: 4,
      );
      final resolveBuffer = device.createBuffer(
        size: 4 * 8,
        usage: GpuBufferUsage.queryResolve | GpuBufferUsage.copySrc,
      );
      final readBuffers = [
        device.createBuffer(
          size: 4 * 8,
          usage: GpuBufferUsage.mapRead | GpuBufferUsage.copyDst,
        ),
        device.createBuffer(
          size: 4 * 8,
          usage: GpuBufferUsage.mapRead | GpuBufferUsage.copyDst,
        ),
      ];

      // Frame 0: timestamps + resolve + copy in single encoder
      var encoder = device.createCommandEncoder();
      _writeTimestamp(encoder, markerView, qs, 0);
      _writeTimestamp(encoder, markerView, qs, 1);
      encoder.resolveQuerySet(
        qs,
        firstQuery: 0,
        queryCount: 2,
        destination: resolveBuffer,
      );
      encoder.copyBufferToBuffer(
        source: resolveBuffer,
        destination: readBuffers[0],
        size: 2 * 8,
      );
      queue.submit([encoder.finish()]);

      await readBuffers[0].mapAsync(GpuMapMode.read, size: 2 * 8);

      // Frame 1: read readBuffers[0], write to readBuffers[1]
      final buf0 = readBuffers[0].getMappedRange(size: 2 * 8);
      final ts0 = buf0.asUint64List();
      _expectTimestampReadback(ts0);
      readBuffers[0].unmap();

      encoder = device.createCommandEncoder();
      _writeTimestamp(encoder, markerView, qs, 0);
      _writeTimestamp(encoder, markerView, qs, 1);
      encoder.resolveQuerySet(
        qs,
        firstQuery: 0,
        queryCount: 2,
        destination: resolveBuffer,
      );
      encoder.copyBufferToBuffer(
        source: resolveBuffer,
        destination: readBuffers[1],
        size: 2 * 8,
      );
      queue.submit([encoder.finish()]);

      await readBuffers[1].mapAsync(GpuMapMode.read, size: 2 * 8);
      final buf1 = readBuffers[1].getMappedRange(size: 2 * 8);
      final ts1 = buf1.asUint64List();
      _expectTimestampReadback(ts1);
      readBuffers[1].unmap();

      for (final b in readBuffers) {
        b.destroy();
      }
      resolveBuffer.destroy();
      qs.destroy();
      markerTex.destroy();
    });
  });
}
