import 'package:gpuweb/gpuweb.dart';

import '../../wgpu_ffi.dart' as wgpu_ffi;
import '../device.dart';
import '../ffi/enum_ffi.dart';
import '../resource.dart';
import '../texture.dart';
import 'iosurface.dart';

extension WgpuAppleDeviceExtension on WgpuDevice {
  WgpuAppleDevice get apple => WgpuAppleDevice(this);
}

final class WgpuAppleDevice {
  const WgpuAppleDevice(this.device);

  final WgpuDevice device;

  WgpuAppleImportedTexture importIOSurfacePlane({
    required WgpuAppleIOSurface iosurface,
    required int plane,
    required int width,
    required int height,
    required GpuTextureFormat format,
    String label = '',
  }) {
    if (plane < 0) throw ArgumentError('plane must not be negative');
    if (width <= 0) throw ArgumentError('width must be positive');
    if (height <= 0) throw ArgumentError('height must be positive');

    final retainedSurface = iosurface.retain();
    final handle = wgpu_ffi.wgpun_DeviceImportIOSurfacePlane(
      device.handle,
      retainedSurface.pointer,
      plane,
      width,
      height,
      format.ffiValue,
    );
    if (handle == 0) {
      retainedSurface.dispose();
      throw StateError(
        'Failed to import IOSurface plane: ${wgpu_ffi.wgpuLastError()}',
      );
    }
    final texture = WgpuTexture.internal(
      handle,
      width: width,
      height: height,
      depthOrArrayLayers: 1,
      dimension: GpuTextureDimension.d2,
      format: format,
      usage: GpuTextureUsage.textureBinding | GpuTextureUsage.copySrc,
      mipLevelCount: 1,
      sampleCount: 1,
      label: label,
    );
    return WgpuAppleImportedTexture._(
      texture: texture,
      iosurface: retainedSurface,
    );
  }
}

final class WgpuAppleImportedTexture implements WgpuResource {
  WgpuAppleImportedTexture._({
    required this.texture,
    required WgpuAppleIOSurface iosurface,
  }) : _iosurface = iosurface;

  final WgpuTexture texture;
  final WgpuAppleIOSurface _iosurface;
  var _disposed = false;

  @override
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    try {
      texture.destroy();
    } finally {
      _iosurface.dispose();
    }
  }
}
