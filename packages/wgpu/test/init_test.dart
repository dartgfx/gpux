import 'package:test/test.dart';
import 'package:wgpu/wgpu.dart';

void main() {
  group('Instance → Adapter → Device', () {
    test('creates instance', () {
      final instance = Wgpu.create();
      expect(instance.handle, isNot(0));
      instance.dispose();
    });

    test('creates instance with debug config', () {
      final instance = Wgpu.create(WgpuInstanceDescriptor.debug);
      expect(instance.handle, isNot(0));
      instance.dispose();
    });

    test('requests adapter from instance', () async {
      final instance = Wgpu.create();
      final adapter = await instance.requestAdapter();

      expect(adapter.handle, isNot(0));

      adapter.dispose();
      instance.dispose();
    });

    test('adapter info returns valid data', () async {
      final instance = Wgpu.create();
      final adapter = await instance.requestAdapter();

      final info = adapter.info;
      expect(WgpuBackendType.values, contains(info.backendType));
      expect(WgpuAdapterType.values, contains(info.adapterType));

      adapter.dispose();
      instance.dispose();
    });

    test('requests adapter with power preference', () async {
      final instance = Wgpu.create();

      final highPerfAdapter = await instance.requestAdapter(
        const GpuRequestAdapterOptions(
          powerPreference: GpuPowerPreference.highPerformance,
        ),
      );
      expect(highPerfAdapter.handle, isNot(0));

      highPerfAdapter.dispose();
      instance.dispose();
    });

    test('requests device from adapter', () async {
      final instance = Wgpu.create();
      final adapter = await instance.requestAdapter();
      final device = await adapter.requestDevice();

      expect(device.handle, isNot(0));
      expect((device.queue).handle, isNot(0));

      adapter.dispose();
      instance.dispose();
    });

    test('requests device with features', () async {
      final instance = Wgpu.create();
      final adapter = await instance.requestAdapter();
      final device = await adapter.requestDevice(
        const GpuDeviceDescriptor(
          requiredFeatures: {GpuFeatureName.timestampQuery},
        ),
      );

      expect(device.handle, isNot(0));

      adapter.dispose();
      instance.dispose();
    });

    test('full chain creates valid resources', () async {
      final instance = Wgpu.create(WgpuInstanceDescriptor.release);
      final adapter = await instance.requestAdapter(
        const GpuRequestAdapterOptions(
          powerPreference: GpuPowerPreference.highPerformance,
        ),
      );
      final device = await adapter.requestDevice();

      expect(instance.handle, isNot(0));
      expect(adapter.handle, isNot(0));
      expect(
        (adapter.info).backendType,
        isNot(WgpuBackendType.undefined),
      );
      expect(device.handle, isNot(0));
      expect((device.queue).handle, isNot(0));

      adapter.dispose();
      instance.dispose();
    });
  });
}
