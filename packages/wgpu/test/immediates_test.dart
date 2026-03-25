// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:wgpu/wgpu.dart';

void main() {
  late WgpuDevice device;
  late WgpuQueue queue;

  setUpAll(() async {
    final instance = Wgpu.create();
    final adapter = await instance.requestAdapter();
    device = await adapter.requestDevice(
      const WgpuDeviceDescriptor(immediates: true),
    );
    queue = device.queue;
  });

  group('Immediates (push constants)', () {
    late WgpuTexture renderTarget;
    late WgpuTextureView view;

    setUp(() {
      renderTarget = device.createTexture(
        width: 64,
        height: 64,
        format: GpuTextureFormat.rgba8Unorm,
        usage: GpuTextureUsage.renderAttachment,
      );
      view = renderTarget.createView();
    });

    tearDown(() {
      view.dispose();
      renderTarget.destroy();
    });

    test('render pass with immediates completes without error', () async {
      device.pushErrorScope(GpuErrorFilter.validation);

      final shader = device.createShaderModule(r'''
        var<immediate> params: vec4<f32>;

        @vertex
        fn vs(@builtin(vertex_index) vi: u32) -> @builtin(position) vec4<f32> {
          return vec4<f32>(0.0, 0.0, 0.0, 1.0) + params;
        }

        @fragment
        fn fs() -> @location(0) vec4<f32> {
          return params;
        }
      ''');

      final pipelineLayout = device.createPipelineLayout(
        [],
        immediateSize: 16,
      );

      final pipeline = device.createRenderPipeline(
        GpuRenderPipelineDescriptor(
          vertexModule: shader,
          vertexEntryPoint: 'vs',
          fragmentModule: shader,
          fragmentEntryPoint: 'fs',
          layout: pipelineLayout,
          colorTargets: [
            const GpuColorTargetState(format: GpuTextureFormat.rgba8Unorm),
          ],
        ),
      );

      final encoder = device.createCommandEncoder();
      final pass = encoder.beginRenderPass(
        colorAttachments: [
          GpuColorAttachment(
            view: view,
            loadOp: GpuLoadOp.clear,
            storeOp: GpuStoreOp.store,
            clearValue: const GpuColor(0, 0, 0, 1),
          ),
        ],
      );

      pass.setPipeline(pipeline);
      pass.setImmediates(0, Float32List.fromList([1.0, 0.0, 0.0, 1.0]));
      pass.draw(vertexCount: 3);
      pass.end();

      final commandBuffer = encoder.finish();
      queue.submit([commandBuffer]);
      device.poll();

      final error = await device.popErrorScope();
      if (error != null) print('Validation error: ${error.message}');
      expect(error, isNull, reason: 'Expected no validation errors');
    });

    test('pipeline layout with immediateSize creates successfully', () async {
      device.pushErrorScope(GpuErrorFilter.validation);

      final layout = device.createPipelineLayout(
        [],
        immediateSize: 64,
      );

      expect(layout.handle, isNot(0));

      // Validate no errors were generated
      final error = await device.popErrorScope();
      if (error != null) print('Layout error: ${error.message}');
      expect(error, isNull);
    });
  });
}
