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

  group('RenderPass', () {
    late WgpuTexture renderTarget;
    late WgpuTextureView view;

    setUp(() {
      renderTarget = device.createTexture(
        width: 256,
        height: 256,
        format: GpuTextureFormat.rgba8Unorm,
        usage: GpuTextureUsage.renderAttachment,
      );
      view = renderTarget.createView();
    });

    tearDown(() {
      view.dispose();
      renderTarget.destroy();
    });

    test('beginRenderPass and end', () {
      final encoder = device.createCommandEncoder();

      final renderPass = encoder.beginRenderPass(
        colorAttachments: [
          GpuColorAttachment(
            view: view,
            loadOp: GpuLoadOp.clear,
            storeOp: GpuStoreOp.store,
            clearValue: const GpuColor(1, 0, 0, 1),
          ),
        ],
      );
      expect(renderPass.handle, isNot(0));

      renderPass.end();

      final cmdBuffer = encoder.finish();
      expect(cmdBuffer.handle, isNot(0));
      queue.submit([cmdBuffer]);
    });

    test('setVertexBuffer', () {
      final vertices = Float32List.fromList([
        0.0,
        0.5,
        0.0,
        -0.5,
        -0.5,
        0.0,
        0.5,
        -0.5,
        0.0,
      ]);
      final vertexBuffer = device.createBuffer(
        size: vertices.lengthInBytes,
        usage: GpuBufferUsage.vertex | GpuBufferUsage.copyDst,
      );
      queue.writeBufferTyped(vertexBuffer, vertices);

      final encoder = device.createCommandEncoder();
      final renderPass = encoder.beginRenderPass(
        colorAttachments: [
          GpuColorAttachment(
            view: view,
            loadOp: GpuLoadOp.clear,
            storeOp: GpuStoreOp.store,
            clearValue: const GpuColor(0, 0, 0, 1),
          ),
        ],
      );

      renderPass.setVertexBuffer(0, vertexBuffer);
      renderPass.end();

      final cmdBuffer = encoder.finish();
      queue.submit([cmdBuffer]);

      vertexBuffer.dispose();
    });

    test('throws when ending twice', () {
      final encoder = device.createCommandEncoder();
      final renderPass = encoder.beginRenderPass(
        colorAttachments: [
          GpuColorAttachment(
            view: view,
            loadOp: GpuLoadOp.clear,
            storeOp: GpuStoreOp.store,
          ),
        ],
      );

      renderPass.end();
      expect(() => renderPass.end(), throwsStateError);

      encoder.finish();
    });

    test('throws when finishing encoder during pass', () {
      final encoder = device.createCommandEncoder();
      encoder.beginRenderPass(
        colorAttachments: [
          GpuColorAttachment(
            view: view,
            loadOp: GpuLoadOp.clear,
            storeOp: GpuStoreOp.store,
          ),
        ],
      );

      expect(() => encoder.finish(), throwsStateError);
    });

    test('throws when beginning nested pass', () {
      final encoder = device.createCommandEncoder();
      encoder.beginRenderPass(
        colorAttachments: [
          GpuColorAttachment(
            view: view,
            loadOp: GpuLoadOp.clear,
            storeOp: GpuStoreOp.store,
          ),
        ],
      );

      expect(
        () => encoder.beginRenderPass(
          colorAttachments: [
            GpuColorAttachment(
              view: view,
              loadOp: GpuLoadOp.clear,
              storeOp: GpuStoreOp.store,
            ),
          ],
        ),
        throwsStateError,
      );
    });
  });

  group('RenderPipeline', () {
    const triangleShader = '''
@vertex
fn vs_main(@builtin(vertex_index) idx: u32) -> @builtin(position) vec4<f32> {
  var pos = array<vec2<f32>, 3>(
    vec2<f32>(0.0, 0.5),
    vec2<f32>(-0.5, -0.5),
    vec2<f32>(0.5, -0.5)
  );
  return vec4<f32>(pos[idx], 0.0, 1.0);
}

@fragment
fn fs_main() -> @location(0) vec4<f32> {
  return vec4<f32>(1.0, 0.0, 0.0, 1.0);
}
''';

    test('creates pipeline', () {
      final shader = device.createShaderModule(triangleShader);

      final pipeline = device.createRenderPipeline(
        GpuRenderPipelineDescriptor(
          layout: null,
          vertexModule: shader,
          vertexEntryPoint: 'vs_main',
          fragmentModule: shader,
          fragmentEntryPoint: 'fs_main',
          colorTargets: [
            const GpuColorTargetState(format: GpuTextureFormat.rgba8Unorm),
          ],
        ),
      );

      expect(pipeline.handle, isNot(0));

      pipeline.dispose();
      shader.dispose();
    });

    test('creates pipeline with vertex buffer layout', () {
      const wgsl = '''
struct VertexInput {
  @location(0) position: vec3<f32>,
}

@vertex
fn vs_main(in: VertexInput) -> @builtin(position) vec4<f32> {
  return vec4<f32>(in.position, 1.0);
}

@fragment
fn fs_main() -> @location(0) vec4<f32> {
  return vec4<f32>(1.0, 1.0, 1.0, 1.0);
}
''';

      final shader = device.createShaderModule(wgsl);

      final pipeline = device.createRenderPipeline(
        GpuRenderPipelineDescriptor(
          layout: null,
          vertexModule: shader,
          vertexEntryPoint: 'vs_main',
          vertexBuffers: [
            const GpuVertexBufferLayout(
              arrayStride: 12,
              attributes: [
                GpuVertexAttribute(
                  format: GpuVertexFormat.float32x3,
                  offset: 0,
                  shaderLocation: 0,
                ),
              ],
            ),
          ],
          fragmentModule: shader,
          fragmentEntryPoint: 'fs_main',
          colorTargets: [
            const GpuColorTargetState(format: GpuTextureFormat.rgba8Unorm),
          ],
        ),
      );

      expect(pipeline.handle, isNot(0));

      pipeline.dispose();
      shader.dispose();
    });

    test('draws triangle', () {
      final shader = device.createShaderModule(triangleShader);

      final pipeline = device.createRenderPipeline(
        GpuRenderPipelineDescriptor(
          layout: null,
          vertexModule: shader,
          vertexEntryPoint: 'vs_main',
          fragmentModule: shader,
          fragmentEntryPoint: 'fs_main',
          colorTargets: [
            const GpuColorTargetState(format: GpuTextureFormat.rgba8Unorm),
          ],
        ),
      );

      final renderTarget = device.createTexture(
        width: 256,
        height: 256,
        format: GpuTextureFormat.rgba8Unorm,
        usage: GpuTextureUsage.renderAttachment,
      );
      final view = renderTarget.createView();

      final encoder = device.createCommandEncoder();
      final renderPass = encoder.beginRenderPass(
        colorAttachments: [
          GpuColorAttachment(
            view: view,
            loadOp: GpuLoadOp.clear,
            storeOp: GpuStoreOp.store,
            clearValue: const GpuColor(0, 0, 0, 1),
          ),
        ],
      );

      renderPass.setPipeline(pipeline);
      renderPass.draw(vertexCount: 3);
      renderPass.end();

      final cmdBuffer = encoder.finish();
      queue.submit([cmdBuffer]);

      view.dispose();
      renderTarget.destroy();
      pipeline.dispose();
      shader.dispose();
    });
  });
}
