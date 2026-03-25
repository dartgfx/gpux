import 'package:test/test.dart';
import 'package:wgpu/wgpu.dart';

void main() {
  late WgpuDevice device;

  setUpAll(() async {
    final instance = Wgpu.create();
    final adapter = await instance.requestAdapter();
    device = await adapter.requestDevice();
  });

  group('Error scopes', () {
    test('popErrorScope returns null when no error', () async {
      device.pushErrorScope(GpuErrorFilter.validation);

      // Valid operation — no error expected.
      device.createBuffer(
        size: 256,
        usage: GpuBufferUsage.vertex | GpuBufferUsage.copyDst,
      );

      final error = await device.popErrorScope();
      expect(error, isNull);
    });

    test('popErrorScope captures validation error', () async {
      device.pushErrorScope(GpuErrorFilter.validation);

      // Invalid: empty WGSL source triggers a validation error.
      try {
        device.createShaderModule('not valid wgsl');
      } catch (_) {
        // createShaderModule may throw synchronously via wgpu —
        // the error should still be captured by the scope.
      }

      final error = await device.popErrorScope();
      expect(error, isA<GpuValidationError>());
      expect(error!.message, isNotEmpty);
    });

    test('nested scopes capture independently', () async {
      device.pushErrorScope(GpuErrorFilter.validation);
      device.pushErrorScope(GpuErrorFilter.validation);

      // Inner scope — no error.
      device.createBuffer(
        size: 64,
        usage: GpuBufferUsage.uniform | GpuBufferUsage.copyDst,
      );
      final inner = await device.popErrorScope();
      expect(inner, isNull);

      // Outer scope — also no error.
      final outer = await device.popErrorScope();
      expect(outer, isNull);
    });
  });
}
