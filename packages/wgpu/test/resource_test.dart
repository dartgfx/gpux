import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:wgpu/wgpu.dart';

void main() {
  late WgpuDevice device;
  late WgpuQueue queue;

  setUpAll(() async {
    final instance = Wgpu.create();
    final adapter = await instance.requestAdapter();
    device = await adapter.requestDevice();
    queue = device.queue;
  });

  group('Buffer', () {
    test('createBuffer returns valid buffer', () {
      final buffer = device.createBuffer(
        size: 256,
        usage: GpuBufferUsage.vertex | GpuBufferUsage.copyDst,
      );

      expect(buffer.handle, isNot(0));
      expect(buffer.size, equals(256));
      expect(
        buffer.usage,
        equals(GpuBufferUsage.vertex | GpuBufferUsage.copyDst),
      );

      buffer.dispose();
    });

    test('writeBuffer writes data', () {
      final buffer = device.createBuffer(
        size: 64,
        usage: GpuBufferUsage.vertex | GpuBufferUsage.copyDst,
      );

      final data = Float32List.fromList([1.0, 2.0, 3.0, 4.0]);
      queue.writeBufferTyped(buffer, data);

      buffer.dispose();
    });
  });

  group('Texture', () {
    test('createTexture returns valid texture', () {
      final texture = device.createTexture(
        width: 64,
        height: 64,
        format: GpuTextureFormat.rgba8Unorm,
        usage: GpuTextureUsage.textureBinding,
      );

      expect(texture.handle, isNot(0));
      expect(texture.width, equals(64));
      expect(texture.height, equals(64));

      texture.dispose();
    });

    test('createTexture with view', () {
      final texture = device.createTexture(
        width: 128,
        height: 128,
        format: GpuTextureFormat.rgba8Unorm,
        usage: GpuTextureUsage.textureBinding,
      );

      final view = texture.createView();
      expect(view.handle, isNot(0));

      view.dispose();
      texture.dispose();
    });
  });

  group('Sampler', () {
    test('createSampler returns valid sampler', () {
      final sampler = device.createSampler(
        magFilter: GpuFilterMode.linear,
        minFilter: GpuFilterMode.linear,
      );

      expect(sampler.handle, isNot(0));

      sampler.dispose();
    });
  });

  group('ShaderModule', () {
    test('createShaderModule compiles WGSL', () {
      const wgsl = '''
@vertex
fn vs_main(@builtin(vertex_index) idx: u32) -> @builtin(position) vec4<f32> {
  return vec4<f32>(0.0, 0.0, 0.0, 1.0);
}

@fragment
fn fs_main() -> @location(0) vec4<f32> {
  return vec4<f32>(1.0, 0.0, 0.0, 1.0);
}
''';

      final shader = device.createShaderModule(wgsl);
      expect(shader.handle, isNot(0));

      shader.dispose();
    });
  });

  group('CommandEncoder', () {
    test('createCommandEncoder and finish', () {
      final encoder = device.createCommandEncoder();
      expect(encoder.handle, isNot(0));

      final commandBuffer = encoder.finish();
      expect(commandBuffer.handle, isNot(0));

      queue.submit([commandBuffer]);
    });

    test('submit empty list does nothing', () {
      queue.submit([]);
    });
  });

  group('Handle-based device resources', () {
    test('creates all resource types', () async {
      final instance = Wgpu.create();
      final adapter = await instance.requestAdapter();
      final dev = await adapter.requestDevice();
      final q = dev.queue;

      final buffer = dev.createBuffer(
        size: 256,
        usage: GpuBufferUsage.vertex | GpuBufferUsage.copyDst,
      );
      expect(buffer.handle, isNot(0));
      expect(buffer.size, equals(256));

      final texture = dev.createTexture(
        width: 64,
        height: 64,
        format: GpuTextureFormat.rgba8Unorm,
        usage: GpuTextureUsage.textureBinding | GpuTextureUsage.copyDst,
      );
      expect(texture.handle, isNot(0));

      final sampler = dev.createSampler();
      expect(sampler.handle, isNot(0));

      final shader = dev.createShaderModule('''
        @vertex
        fn vs_main(@builtin(vertex_index) vi: u32) -> @builtin(position) vec4<f32> {
          return vec4<f32>(0.0, 0.0, 0.0, 1.0);
        }
      ''');
      expect(shader.handle, isNot(0));

      final encoder = dev.createCommandEncoder();
      expect(encoder.handle, isNot(0));

      q.writeBuffer(buffer, Uint8List(64));
      final commandBuffer = encoder.finish();
      q.submit([commandBuffer]);

      buffer.dispose();
      texture.dispose();
      sampler.dispose();
      shader.dispose();
      adapter.dispose();
      instance.dispose();
    });
  });
}
