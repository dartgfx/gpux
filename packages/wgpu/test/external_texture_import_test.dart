import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:wgpu/wgpu.dart';

void main() {
  test('imports a manually allocated Metal texture', () async {
    if (!Platform.isMacOS) {
      markTestSkipped('Metal texture import test only runs on macOS');
      return;
    }

    final metal = _MetalTestApi();
    final mtlDevice = metal.createDefaultDevice();
    if (mtlDevice == nullptr) {
      markTestSkipped('No default Metal device is available');
      return;
    }

    final instance = Wgpu.create(
      const WgpuInstanceDescriptor(backends: WgpuBackend.metal),
    );
    final adapter = await instance.requestAdapter();
    final device = await adapter.requestDevice();

    WgpuTexture? imported;
    Pointer<Void> mtlTexture = nullptr;
    try {
      final descriptor = metal.texture2DDescriptor(
        pixelFormat: _mtlPixelFormatBgra8Unorm,
        width: 32,
        height: 16,
      );
      metal.setUsage(descriptor, _mtlTextureUsageShaderRead);
      mtlTexture = metal.newTexture(mtlDevice, descriptor);
      expect(mtlTexture, isNot(nullptr));

      imported = WgpuTexture.fromMetalTexture(
        device,
        mtlTexture,
        GpuTextureFormat.bgra8Unorm,
        32,
        16,
      );

      expect(imported.handle, isNot(0));
      expect(imported.width, 32);
      expect(imported.height, 16);
    } finally {
      imported?.dispose();
      if (mtlTexture != nullptr) {
        metal.release(mtlTexture);
      }
      metal.release(mtlDevice);
      adapter.dispose();
      instance.dispose();
    }
  });
}

const _mtlPixelFormatBgra8Unorm = 80;
const _mtlTextureUsageShaderRead = 0x0001;

class _MetalTestApi {
  _MetalTestApi()
    : _metal = DynamicLibrary.open(
        '/System/Library/Frameworks/Metal.framework/Metal',
      ),
      _objc = _openObjc();

  final DynamicLibrary _metal;
  final DynamicLibrary _objc;

  late final Pointer<Void> Function() createDefaultDevice = _metal
      .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
        'MTLCreateSystemDefaultDevice',
      );

  late final Pointer<Void> Function(Pointer<Char>) _objcGetClass = _objc
      .lookupFunction<
        Pointer<Void> Function(Pointer<Char>),
        Pointer<Void> Function(Pointer<Char>)
      >('objc_getClass');

  late final Pointer<Void> Function(Pointer<Char>) _selRegisterName = _objc
      .lookupFunction<
        Pointer<Void> Function(Pointer<Char>),
        Pointer<Void> Function(Pointer<Char>)
      >('sel_registerName');

  late final void Function(Pointer<Void>) release = _objc
      .lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('objc_release');

  late final Pointer<Void> Function(
    Pointer<Void>,
    Pointer<Void>,
    int,
    int,
    int,
    int,
  )
  _texture2DDescriptorWithPixelFormat = _objc
      .lookupFunction<
        Pointer<Void> Function(
          Pointer<Void>,
          Pointer<Void>,
          Uint64,
          Uint64,
          Uint64,
          Uint8,
        ),
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>, int, int, int, int)
      >('objc_msgSend');

  late final void Function(Pointer<Void>, Pointer<Void>, int) _setUsage = _objc
      .lookupFunction<
        Void Function(Pointer<Void>, Pointer<Void>, Uint64),
        void Function(Pointer<Void>, Pointer<Void>, int)
      >('objc_msgSend');

  late final Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Pointer<Void>)
  _newTextureWithDescriptor = _objc
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Pointer<Void>),
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Pointer<Void>)
      >('objc_msgSend');

  Pointer<Void> texture2DDescriptor({
    required int pixelFormat,
    required int width,
    required int height,
  }) {
    final descriptorClass = _class('MTLTextureDescriptor');
    final selector = _selector(
      'texture2DDescriptorWithPixelFormat:width:height:mipmapped:',
    );
    return _texture2DDescriptorWithPixelFormat(
      descriptorClass,
      selector,
      pixelFormat,
      width,
      height,
      0,
    );
  }

  void setUsage(Pointer<Void> descriptor, int usage) {
    _setUsage(descriptor, _selector('setUsage:'), usage);
  }

  Pointer<Void> newTexture(Pointer<Void> device, Pointer<Void> descriptor) {
    return _newTextureWithDescriptor(
      device,
      _selector('newTextureWithDescriptor:'),
      descriptor,
    );
  }

  Pointer<Void> _class(String name) {
    return using((arena) {
      return _objcGetClass(name.toNativeUtf8(allocator: arena).cast());
    });
  }

  Pointer<Void> _selector(String name) {
    return using((arena) {
      return _selRegisterName(name.toNativeUtf8(allocator: arena).cast());
    });
  }
}

DynamicLibrary _openObjc() {
  try {
    return DynamicLibrary.open('/usr/lib/libobjc.A.dylib');
  } on ArgumentError {
    return DynamicLibrary.process();
  }
}
