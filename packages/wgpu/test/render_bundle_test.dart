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

  group('RenderBundle', () {
    late WgpuRenderPipeline pipeline;
    late WgpuShaderModule shader;

    setUp(() {
      shader = device.createShaderModule(triangleShader);
      pipeline = device.createRenderPipeline(
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
    });

    tearDown(() {
      pipeline.dispose();
      shader.dispose();
    });

    test('create encoder, record, finish, execute', () async {
      device.pushErrorScope(GpuErrorFilter.validation);

      // Create render bundle encoder with matching format
      final bundleEncoder = device.createRenderBundleEncoder(
        const GpuRenderBundleEncoderDescriptor(
          colorFormats: [GpuTextureFormat.rgba8Unorm],
          label: 'test-bundle',
        ),
      );
      expect(bundleEncoder.handle, isNot(0));

      // Record draw commands
      bundleEncoder.setPipeline(pipeline);
      bundleEncoder.draw(vertexCount: 3);

      // Finish to get bundle
      final bundle = bundleEncoder.finish(label: 'triangle-bundle');
      expect(bundle.handle, isNot(0));

      // Create render target and execute the bundle
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

      renderPass.executeBundles([bundle]);
      renderPass.end();

      final cmdBuffer = encoder.finish();
      queue.submit([cmdBuffer]);

      view.dispose();
      renderTarget.destroy();
      bundle.dispose();

      // Verify no GPU errors
      final error = await device.popErrorScope();
      expect(error, isNull, reason: 'GPU validation error: $error');
    });

    test('throws when finishing twice', () {
      final bundleEncoder = device.createRenderBundleEncoder(
        const GpuRenderBundleEncoderDescriptor(
          colorFormats: [GpuTextureFormat.rgba8Unorm],
        ),
      );

      bundleEncoder.setPipeline(pipeline);
      bundleEncoder.draw(vertexCount: 3);
      bundleEncoder.finish();

      expect(() => bundleEncoder.finish(), throwsStateError);
    });

    test('throws when recording after finish', () {
      final bundleEncoder = device.createRenderBundleEncoder(
        const GpuRenderBundleEncoderDescriptor(
          colorFormats: [GpuTextureFormat.rgba8Unorm],
        ),
      );

      bundleEncoder.setPipeline(pipeline);
      bundleEncoder.finish();

      expect(() => bundleEncoder.draw(vertexCount: 3), throwsStateError);
    });

    test('with depth stencil format', () async {
      final depthShader = device.createShaderModule(triangleShader);
      final depthPipeline = device.createRenderPipeline(
        GpuRenderPipelineDescriptor(
          layout: null,
          vertexModule: depthShader,
          vertexEntryPoint: 'vs_main',
          fragmentModule: depthShader,
          fragmentEntryPoint: 'fs_main',
          colorTargets: [
            const GpuColorTargetState(format: GpuTextureFormat.rgba8Unorm),
          ],
          depthStencil: const GpuDepthStencilState(
            format: GpuTextureFormat.depth24Plus,
            depthWriteEnabled: true,
            depthCompare: GpuCompareFunction.less,
          ),
        ),
      );

      device.pushErrorScope(GpuErrorFilter.validation);

      final bundleEncoder = device.createRenderBundleEncoder(
        const GpuRenderBundleEncoderDescriptor(
          colorFormats: [GpuTextureFormat.rgba8Unorm],
          depthStencilFormat: GpuTextureFormat.depth24Plus,
        ),
      );

      bundleEncoder.setPipeline(depthPipeline);
      bundleEncoder.draw(vertexCount: 3);
      final bundle = bundleEncoder.finish();

      // Execute in a render pass with depth attachment
      final colorTarget = device.createTexture(
        width: 256,
        height: 256,
        format: GpuTextureFormat.rgba8Unorm,
        usage: GpuTextureUsage.renderAttachment,
      );
      final colorView = colorTarget.createView();

      final depthTarget = device.createTexture(
        width: 256,
        height: 256,
        format: GpuTextureFormat.depth24Plus,
        usage: GpuTextureUsage.renderAttachment,
      );
      final depthView = depthTarget.createView();

      final encoder = device.createCommandEncoder();
      final renderPass = encoder.beginRenderPass(
        colorAttachments: [
          GpuColorAttachment(
            view: colorView,
            loadOp: GpuLoadOp.clear,
            storeOp: GpuStoreOp.store,
            clearValue: const GpuColor(0, 0, 0, 1),
          ),
        ],
        depthStencilAttachment: GpuDepthStencilAttachment(
          view: depthView,
          depthLoadOp: GpuLoadOp.clear,
          depthStoreOp: GpuStoreOp.store,
          depthClearValue: 1.0,
        ),
      );

      renderPass.executeBundles([bundle]);
      renderPass.end();

      final cmdBuffer = encoder.finish();
      queue.submit([cmdBuffer]);

      depthView.dispose();
      depthTarget.destroy();
      colorView.dispose();
      colorTarget.destroy();
      bundle.dispose();
      depthPipeline.dispose();
      depthShader.dispose();

      final error = await device.popErrorScope();
      expect(error, isNull, reason: 'GPU validation error: $error');
    });
  });
}
