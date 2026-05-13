import 'package:gpuweb/gpuweb.dart';

import '../../wgpu_ffi.dart' as wgpu_ffi;
import '../device.dart';
import '../ffi/enum_ffi.dart';
import '../resource.dart';
import '../texture.dart';
import 'hardware_buffer.dart';

extension WgpuAndroidDeviceExtension on WgpuDevice {
  WgpuAndroidDevice get android => WgpuAndroidDevice(this);
}

final class WgpuAndroidDevice {
  const WgpuAndroidDevice(this.device);

  final WgpuDevice device;

  /// Imports an [WgpuAndroidHardwareBuffer] as a sampleable wgpu texture.
  ///
  /// The returned [WgpuAndroidImportedTexture] owns an independent acquire on
  /// the source [buffer]; disposing it releases both the imported texture and
  /// the acquired reference.
  WgpuAndroidImportedTexture importHardwareBuffer({
    required WgpuAndroidHardwareBuffer buffer,
    required int width,
    required int height,
    required GpuTextureFormat format,
    String label = '',
  }) {
    if (width <= 0) throw ArgumentError('width must be positive');
    if (height <= 0) throw ArgumentError('height must be positive');

    final acquired = buffer.acquire();
    final handle = wgpu_ffi.wgpun_DeviceImportAHardwareBuffer(
      device.handle,
      acquired.pointer,
      width,
      height,
      format.ffiValue,
    );
    if (handle == 0) {
      acquired.dispose();
      throw StateError(
        'Failed to import AHardwareBuffer: ${wgpu_ffi.wgpuLastError()}',
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
    return WgpuAndroidImportedTexture._(
      texture: texture,
      buffer: acquired,
    );
  }
}

final class WgpuAndroidImportedTexture implements WgpuResource {
  WgpuAndroidImportedTexture._({
    required this.texture,
    required WgpuAndroidHardwareBuffer buffer,
  }) : _buffer = buffer;

  final WgpuTexture texture;
  final WgpuAndroidHardwareBuffer _buffer;
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
      _buffer.dispose();
    }
  }
}
