import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:wgpu/wgpu.dart';
import 'package:wgpu/wgpu_android.dart';

void main() {
  test('imports a manually allocated Android hardware buffer', () async {
    if (!Platform.isAndroid) {
      markTestSkipped('AHardwareBuffer import test only runs on Android');
      return;
    }

    final android = _AndroidHardwareBufferTestApi();
    final ahb = android.allocateRgba(width: 32, height: 16);
    if (ahb == nullptr) {
      markTestSkipped('RGBA8 GPU-sampled AHardwareBuffer allocation failed');
      return;
    }

    final instance = Wgpu.create(
      const WgpuInstanceDescriptor(backends: WgpuBackend.vulkan),
    );
    final adapter = await instance.requestAdapter();
    final device = await adapter.requestDevice(
      const WgpuDeviceDescriptor(requireAndroidAhbImport: true),
    );

    WgpuAndroidImportedTexture? imported;
    WgpuAndroidHardwareBuffer? buffer;
    try {
      buffer = WgpuAndroidHardwareBuffer.acquireAddress(ahb.address);
      imported = device.android.importHardwareBuffer(
        buffer: buffer,
        width: 32,
        height: 16,
        format: GpuTextureFormat.rgba8Unorm,
        label: 'External AHardwareBuffer texture',
      );

      expect(imported.texture.handle, isNot(0));
      expect(imported.texture.width, 32);
      expect(imported.texture.height, 16);
      expect(
        imported.texture.usage & GpuTextureUsage.textureBinding,
        GpuTextureUsage.textureBinding,
      );
    } finally {
      imported?.dispose();
      buffer?.dispose();
      android.release(ahb);
      adapter.dispose();
      instance.dispose();
    }
  });
}

final class _AHardwareBufferDesc extends Struct {
  @Uint32()
  external int width;

  @Uint32()
  external int height;

  @Uint32()
  external int layers;

  @Uint32()
  external int format;

  @Uint64()
  external int usage;

  @Uint32()
  external int stride;

  @Uint32()
  external int rfu0;

  @Uint64()
  external int rfu1;
}

const _ahardwareBufferFormatRgba8Unorm = 1;
const _ahardwareBufferUsageGpuSampledImage = 0x100;

class _AndroidHardwareBufferTestApi {
  _AndroidHardwareBufferTestApi()
    : _android = DynamicLibrary.open('libandroid.so');

  final DynamicLibrary _android;

  late final int Function(Pointer<_AHardwareBufferDesc>, Pointer<Pointer<Void>>)
  _allocate = _android
      .lookupFunction<
        Int32 Function(Pointer<_AHardwareBufferDesc>, Pointer<Pointer<Void>>),
        int Function(Pointer<_AHardwareBufferDesc>, Pointer<Pointer<Void>>)
      >('AHardwareBuffer_allocate');

  late final int Function(Pointer<_AHardwareBufferDesc>) _isSupported = _android
      .lookupFunction<
        Int32 Function(Pointer<_AHardwareBufferDesc>),
        int Function(Pointer<_AHardwareBufferDesc>)
      >('AHardwareBuffer_isSupported');

  late final void Function(Pointer<Void>) release = _android
      .lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('AHardwareBuffer_release');

  Pointer<Void> allocateRgba({required int width, required int height}) {
    final desc = calloc<_AHardwareBufferDesc>();
    final out = calloc<Pointer<Void>>();
    try {
      desc.ref
        ..width = width
        ..height = height
        ..layers = 1
        ..format = _ahardwareBufferFormatRgba8Unorm
        ..usage = _ahardwareBufferUsageGpuSampledImage
        ..stride = 0
        ..rfu0 = 0
        ..rfu1 = 0;

      if (_isSupported(desc) == 0) {
        return nullptr;
      }
      if (_allocate(desc, out) != 0) {
        return nullptr;
      }
      return out.value;
    } finally {
      calloc.free(out);
      calloc.free(desc);
    }
  }
}
