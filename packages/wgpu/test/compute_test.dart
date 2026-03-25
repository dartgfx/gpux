import 'package:test/test.dart';
import 'package:wgpu/wgpu.dart';

void main() {
  late WgpuDevice device;
  late GpuQueue queue;

  setUpAll(() async {
    final instance = Wgpu.create();
    final adapter = await instance.requestAdapter();
    device = await adapter.requestDevice();
    queue = device.queue;
  });

  group('ComputePass', () {
    test('beginComputePass and end', () {
      final encoder = device.createCommandEncoder();

      final computePass = encoder.beginComputePass();
      expect(computePass.handle, isNot(0));

      computePass.end();

      final cmdBuffer = encoder.finish();
      queue.submit([cmdBuffer]);
    });

    test('throws when ending twice', () {
      final encoder = device.createCommandEncoder();
      final computePass = encoder.beginComputePass();

      computePass.end();
      expect(() => computePass.end(), throwsStateError);

      encoder.finish();
    });
  });

  group('ComputePipeline', () {
    const computeShader = '''
@group(0) @binding(0) var<storage, read_write> data: array<f32>;

@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) id: vec3<u32>) {
  data[id.x] = data[id.x] * 2.0;
}
''';

    test('creates pipeline', () {
      final shader = device.createShaderModule(computeShader);

      final bindGroupLayout = device.createBindGroupLayout(
        [
          const GpuBindGroupLayoutEntry.buffer(
            binding: 0,
            visibility: GpuShaderStage.compute,
            type: GpuBufferBindingType.storage,
          ),
        ],
      );

      final pipelineLayout = device.createPipelineLayout(
        [bindGroupLayout],
      );

      final pipeline = device.createComputePipeline(
        module: shader,
        entryPoint: 'main',
        layout: pipelineLayout,
      );

      expect(pipeline.handle, isNot(0));

      pipeline.dispose();
      pipelineLayout.dispose();
      bindGroupLayout.dispose();
      shader.dispose();
    });

    test('dispatches workgroups', () {
      final shader = device.createShaderModule(computeShader);

      final bindGroupLayout = device.createBindGroupLayout(
        [
          const GpuBindGroupLayoutEntry.buffer(
            binding: 0,
            visibility: GpuShaderStage.compute,
            type: GpuBufferBindingType.storage,
          ),
        ],
      );

      final pipelineLayout = device.createPipelineLayout(
        [bindGroupLayout],
      );

      final pipeline = device.createComputePipeline(
        module: shader,
        entryPoint: 'main',
        layout: pipelineLayout,
      );

      final buffer = device.createBuffer(
        size: 256,
        usage: GpuBufferUsage.storage | GpuBufferUsage.copyDst,
      );

      final bindGroup = device.createBindGroup(
        layout: bindGroupLayout,
        entries: [
          GpuBindGroupEntry.buffer(binding: 0, buffer: buffer),
        ],
      );

      final encoder = device.createCommandEncoder();
      final computePass = encoder.beginComputePass();

      computePass.setPipeline(pipeline);
      computePass.setBindGroup(0, bindGroup);
      computePass.dispatchWorkgroups(1);
      computePass.end();

      final cmdBuffer = encoder.finish();
      queue.submit([cmdBuffer]);

      bindGroup.dispose();
      buffer.dispose();
      pipeline.dispose();
      pipelineLayout.dispose();
      bindGroupLayout.dispose();
      shader.dispose();
    });
  });
}
