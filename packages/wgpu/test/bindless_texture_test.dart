/// E2E test: bindless texture arrays through the full stack.
///
/// Proves: shadespeare DSL → WGSL binding_array → wgpu FFI → GPU → readback
///
/// The compute shader receives 4 tiny 1x1 textures as a binding_array,
/// reads each one by index via textureLoad, and writes the RGBA values
/// to an output storage buffer. Dart reads back and verifies.
///
/// Run with: fvm dart test packages/wgpu/test/bindless_texture_test.dart
library;

import 'dart:typed_data';

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

  test('bindless texture array: compute shader reads 4 textures by index', () {
    // --- 1. Create 4 tiny 1x1 RGBA textures, each a solid color ---
    //
    //   [0] = red    (1, 0, 0, 1)
    //   [1] = green  (0, 1, 0, 1)
    //   [2] = blue   (0, 0, 1, 1)
    //   [3] = white  (1, 1, 1, 1)

    final colors = <Uint8List>[
      Uint8List.fromList([255, 0, 0, 255]), // red
      Uint8List.fromList([0, 255, 0, 255]), // green
      Uint8List.fromList([0, 0, 255, 255]), // blue
      Uint8List.fromList([255, 255, 255, 255]), // white
    ];

    final textures = <GpuTexture>[];
    final views = <WgpuTextureView>[];

    for (final color in colors) {
      final tex = device.createTexture(
        width: 1,
        height: 1,
        format: GpuTextureFormat.rgba8Unorm,
        usage: GpuTextureUsage.textureBinding | GpuTextureUsage.copyDst,
      );
      queue.writeTexture(
        texture: tex,
        data: color,
        bytesPerRow: 4,
        width: 1,
        height: 1,
      );
      textures.add(tex);
      views.add(tex.createView());
    }

    // --- 2. Create output buffer (4 textures × 4 floats RGBA = 64 bytes) ---

    final outputBuffer = device.createBuffer(
      size: 64,
      usage: GpuBufferUsage.storage | GpuBufferUsage.copySrc,
    );

    // --- 3. WGSL compute shader using binding_array ---

    const wgsl = '''
@group(0) @binding(0)
var textures: binding_array<texture_2d<f32>, 4>;

@group(0) @binding(1)
var<storage, read_write> output: array<vec4<f32>>;

@compute @workgroup_size(4)
fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
  let i = gid.x;
  output[i] = textureLoad(textures[i], vec2<u32>(0u, 0u), 0);
}
''';

    final shader = device.createShaderModule(wgsl);

    // --- 4. Bind group layout: texture array + storage buffer ---

    final bindGroupLayout = device.createBindGroupLayout(
      [
        const GpuBindGroupLayoutEntry.texture(
          binding: 0,
          visibility: GpuShaderStage.compute,
          sampleType: GpuTextureSampleType.float,
        ),
        const GpuBindGroupLayoutEntry.buffer(
          binding: 1,
          visibility: GpuShaderStage.compute,
          type: GpuBufferBindingType.storage,
        ),
      ],
      bindingArraySizes: {0: 4},
    );

    // --- 5. Bind group: pass texture view array + output buffer ---

    final bindGroup = device.createBindGroup(
      layout: bindGroupLayout,
      entries: [
        WgpuTextureViewArrayBinding(binding: 0, views: views),
        GpuBindGroupEntry.buffer(binding: 1, buffer: outputBuffer),
      ],
    );

    // --- 6. Pipeline ---

    final pipelineLayout = device.createPipelineLayout(
      [bindGroupLayout],
    );

    final pipeline = device.createComputePipeline(
      module: shader,
      entryPoint: 'main',
      layout: pipelineLayout,
    );

    // --- 7. Dispatch ---

    final encoder = device.createCommandEncoder();
    final pass = encoder.beginComputePass();
    pass.setPipeline(pipeline);
    pass.setBindGroup(0, bindGroup);
    pass.dispatchWorkgroups(1);
    pass.end();

    // Copy output to readable buffer
    final readBuffer = device.createBuffer(
      size: 64,
      usage: GpuBufferUsage.copyDst | GpuBufferUsage.copySrc,
    );
    encoder.copyBufferToBuffer(
      source: outputBuffer,
      destination: readBuffer,
      size: 64,
    );

    queue.submit([encoder.finish()]);

    // --- 8. Read back and verify ---

    final mapping = readBuffer.mapRead();
    var pollCount = 0;
    while (!mapping.isReady) {
      device.poll(wait: false);
      pollCount++;
      if (pollCount > 10000) fail('Buffer mapping took too long');
    }

    final result = mapping.readTyped<Float32List>();
    mapping.dispose();

    // texture[0] = red   (1.0, 0.0, 0.0, 1.0)
    expect(result[0], closeTo(1.0, 0.01), reason: 'red R');
    expect(result[1], closeTo(0.0, 0.01), reason: 'red G');
    expect(result[2], closeTo(0.0, 0.01), reason: 'red B');
    expect(result[3], closeTo(1.0, 0.01), reason: 'red A');

    // texture[1] = green (0.0, 1.0, 0.0, 1.0)
    expect(result[4], closeTo(0.0, 0.01), reason: 'green R');
    expect(result[5], closeTo(1.0, 0.01), reason: 'green G');
    expect(result[6], closeTo(0.0, 0.01), reason: 'green B');
    expect(result[7], closeTo(1.0, 0.01), reason: 'green A');

    // texture[2] = blue  (0.0, 0.0, 1.0, 1.0)
    expect(result[8], closeTo(0.0, 0.01), reason: 'blue R');
    expect(result[9], closeTo(0.0, 0.01), reason: 'blue G');
    expect(result[10], closeTo(1.0, 0.01), reason: 'blue B');
    expect(result[11], closeTo(1.0, 0.01), reason: 'blue A');

    // texture[3] = white (1.0, 1.0, 1.0, 1.0)
    expect(result[12], closeTo(1.0, 0.01), reason: 'white R');
    expect(result[13], closeTo(1.0, 0.01), reason: 'white G');
    expect(result[14], closeTo(1.0, 0.01), reason: 'white B');
    expect(result[15], closeTo(1.0, 0.01), reason: 'white A');

    // --- Cleanup ---
    readBuffer.dispose();
    outputBuffer.dispose();
    pipeline.dispose();
    pipelineLayout.dispose();
    bindGroup.dispose();
    bindGroupLayout.dispose();
    shader.dispose();
    for (final v in views) {
      v.dispose();
    }
    for (final t in textures) {
      t.destroy();
    }
  });
}
