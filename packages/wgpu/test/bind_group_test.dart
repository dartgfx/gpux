import 'package:test/test.dart';
import 'package:wgpu/wgpu.dart';

void main() {
  late WgpuDevice device;

  setUpAll(() async {
    final instance = Wgpu.create();
    final adapter = await instance.requestAdapter();
    device = await adapter.requestDevice();
  });

  group('BindGroupLayout', () {
    test('creates layout with buffer binding', () {
      final layout = device.createBindGroupLayout(
        [
          const GpuBindGroupLayoutEntry.buffer(
            binding: 0,
            visibility: GpuShaderStage.vertex,
            type: GpuBufferBindingType.uniform,
          ),
        ],
      );

      expect(layout.handle, isNot(0));
      layout.dispose();
    });

    test('creates layout with sampler and texture bindings', () {
      final layout = device.createBindGroupLayout(
        [
          const GpuBindGroupLayoutEntry.sampler(
            binding: 0,
            visibility: GpuShaderStage.fragment,
          ),
          const GpuBindGroupLayoutEntry.texture(
            binding: 1,
            visibility: GpuShaderStage.fragment,
          ),
        ],
      );

      expect(layout.handle, isNot(0));
      layout.dispose();
    });

    test('creates layout with storage texture binding', () {
      final layout = device.createBindGroupLayout(
        [
          const GpuBindGroupLayoutEntry.storageTexture(
            binding: 0,
            format: GpuTextureFormat.rgba8Unorm,
            visibility: GpuShaderStage.compute,
            access: GpuStorageTextureAccess.writeOnly,
          ),
        ],
      );

      expect(layout.handle, isNot(0));
      layout.dispose();
    });
  });

  group('BindGroup', () {
    test('creates bind group with buffer', () {
      final layout = device.createBindGroupLayout(
        [
          const GpuBindGroupLayoutEntry.buffer(
            binding: 0,
            visibility: GpuShaderStage.vertex,
            type: GpuBufferBindingType.uniform,
          ),
        ],
      );

      final buffer = device.createBuffer(
        size: 64,
        usage: GpuBufferUsage.uniform | GpuBufferUsage.copyDst,
      );

      final bindGroup = device.createBindGroup(
        layout: layout,
        entries: [
          GpuBindGroupEntry.buffer(binding: 0, buffer: buffer),
        ],
      );

      expect(bindGroup.handle, isNot(0));

      bindGroup.dispose();
      buffer.dispose();
      layout.dispose();
    });
  });

  group('PipelineLayout', () {
    test('creates layout with bind group layouts', () {
      final bindGroupLayout = device.createBindGroupLayout(
        [
          const GpuBindGroupLayoutEntry.buffer(
            binding: 0,
            visibility: GpuShaderStage.vertex,
          ),
        ],
      );

      final pipelineLayout = device.createPipelineLayout(
        [bindGroupLayout],
      );

      expect(pipelineLayout.handle, isNot(0));

      pipelineLayout.dispose();
      bindGroupLayout.dispose();
    });

    test('creates empty layout', () {
      final pipelineLayout = device.createPipelineLayout(
        [],
      );

      expect(pipelineLayout.handle, isNot(0));

      pipelineLayout.dispose();
    });
  });
}
