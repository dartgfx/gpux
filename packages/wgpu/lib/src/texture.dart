import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:gpuweb/gpuweb.dart';
import '../wgpu_ffi.dart' show wgpuLastError;
import 'ffi/bindings_generated.dart' as ffi;
import 'ffi/enum_ffi.dart';
import 'resource.dart';

/// A GPU texture.
class WgpuTexture extends WgpuNativeResource implements GpuTexture {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_TextureRelease_p,
    ),
  );

  @override
  String label;
  @override
  final int width;
  @override
  final int height;
  @override
  final int depthOrArrayLayers;
  @override
  final GpuTextureDimension dimension;
  @override
  final GpuTextureFormat format;
  @override
  final int usage;
  @override
  final int mipLevelCount;
  @override
  final int sampleCount;

  final GpuTextureViewDimension? _textureBindingViewDimension;

  @override
  GpuTextureViewDimension get textureBindingViewDimension =>
      _textureBindingViewDimension ??
      switch (dimension) {
        GpuTextureDimension.d1 => GpuTextureViewDimension.d1,
        GpuTextureDimension.d3 => GpuTextureViewDimension.d3,
        GpuTextureDimension.d2 =>
          depthOrArrayLayers > 1
              ? GpuTextureViewDimension.d2Array
              : GpuTextureViewDimension.d2,
      };

  WgpuTexture.internal(
    int handle, {
    required this.width,
    required this.height,
    required this.depthOrArrayLayers,
    this.dimension = GpuTextureDimension.d2,
    required this.format,
    required this.usage,
    required this.mipLevelCount,
    this.sampleCount = 1,
    this.label = '',
    GpuTextureViewDimension? textureBindingViewDimension,
  }) : _textureBindingViewDimension = textureBindingViewDimension,
       super(handle, _fin);

  int get handle => nativeHandle;

  @override
  NativeFinalizer get finalizer => _fin;
  @override
  void release(int handle) => ffi.wgpun_TextureRelease(handle);

  /// Creates a view into this texture.
  @override
  WgpuTextureView createView({
    GpuTextureFormat? format,
    GpuTextureViewDimension? dimension,
    GpuTextureUsageFlags? usage,
    int baseMipLevel = 0,
    int? mipLevelCount,
    int baseArrayLayer = 0,
    int? arrayLayerCount,
    GpuTextureAspect aspect = GpuTextureAspect.all,
    String swizzle = 'rgba',
    String label = '',
  }) {
    if (isDisposed) throw StateError('Texture already disposed');

    final hasDescriptor =
        format != null ||
        dimension != null ||
        usage != null ||
        baseMipLevel != 0 ||
        mipLevelCount != null ||
        baseArrayLayer != 0 ||
        arrayLayerCount != null ||
        aspect != GpuTextureAspect.all;

    if (!hasDescriptor) {
      final viewHandle = ffi.wgpun_TextureCreateView(nativeHandle, nullptr);
      if (viewHandle == 0) {
        throw StateError('Failed to create texture view: ${wgpuLastError()}');
      }
      return WgpuTextureView.internal(viewHandle, label: label);
    }

    return using((arena) {
      final desc = arena<ffi.WGPUTextureViewDescriptor>();
      desc.ref.format = (format ?? this.format).ffiValue;
      desc.ref.dimension = (dimension ?? GpuTextureViewDimension.d2).ffiValue;
      desc.ref.base_mip_level = baseMipLevel;
      desc.ref.mip_level_count = mipLevelCount ?? 0;
      desc.ref.base_array_layer = baseArrayLayer;
      desc.ref.array_layer_count = arrayLayerCount ?? 0;
      desc.ref.aspect = aspect.ffiValue;
      desc.ref.usage = usage ?? 0;
      if (label.isNotEmpty) {
        desc.ref.label = label.toNativeUtf8(allocator: arena).cast();
      }

      final viewHandle = ffi.wgpun_TextureCreateView(nativeHandle, desc);
      if (viewHandle == 0) {
        throw StateError('Failed to create texture view: ${wgpuLastError()}');
      }
      return WgpuTextureView.internal(viewHandle, label: label);
    });
  }

  @override
  void destroy() => dispose();
}

/// A view into a texture.
class WgpuTextureView extends WgpuNativeResource implements GpuTextureView {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_TextureViewRelease_p,
    ),
  );

  @override
  String label;

  WgpuTextureView.internal(int handle, {this.label = ''}) : super(handle, _fin);

  int get handle => nativeHandle;

  @override
  NativeFinalizer get finalizer => _fin;
  @override
  void release(int handle) => ffi.wgpun_TextureViewRelease(handle);
}
