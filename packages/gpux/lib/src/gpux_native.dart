import 'dart:developer' as dev;

import 'package:wgpu/wgpu.dart';

import 'capabilities.dart';
import 'blocklist.dart' as blocklist;
import 'workarounds.dart';

/// Bit positions matching wgpu's `DownlevelFlags`.
const _downlevelBits = {
  GpuCapability.computeShaders: 1 << 0,
  GpuCapability.indirectExecution: 1 << 2,
  GpuCapability.vertexStorage: 1 << 9,
  GpuCapability.anisotropicFiltering: 1 << 10,
  GpuCapability.fragmentStorage: 1 << 11,
  GpuCapability.independentBlend: 1 << 8,
};

/// Cross-platform GPU instance (native implementation).
///
/// Delegates to [Wgpu] via wgpu FFI bindings. On Android, automatically
/// falls back from Vulkan to GLES if the GPU is on the blocklist.
class Gpu implements GpuInstance {
  /// Creates a GPU instance.
  Gpu() : _instance = Wgpu.create();

  Wgpu _instance;

  @override
  GpuTextureFormat get preferredCanvasFormat => _instance.preferredCanvasFormat;

  @override
  Set<GpuWgslLanguageFeatureName> get wgslLanguageFeatures =>
      _instance.wgslLanguageFeatures;

  @override
  Future<GpuAdapter> requestAdapter([
    GpuRequestAdapterOptions options = const GpuRequestAdapterOptions(),
  ]) async {
    var adapter = await _instance.requestAdapter(options);
    var info = adapter.info;
    dev.log(
      'adapter: ${info.device} vendor=0x${info.vendorId.toRadixString(16)}'
      ' backend=${info.backendType} type=${info.adapterType}',
      name: 'gpux',
    );

    // Check if this Vulkan adapter is on the blocklist.
    if (blocklist.isBlocklisted(info)) {
      dev.log('blocklisted — falling back to GLES', name: 'gpux');
      adapter.dispose();
      _instance.dispose();
      _instance = Wgpu.create(
        const WgpuInstanceDescriptor(backends: WgpuBackend.gl),
      );
      adapter = await _instance.requestAdapter(options);
      info = adapter.info;
      dev.log(
        'fallback adapter: ${info.device} backend=${info.backendType}',
        name: 'gpux',
      );
    }

    return adapter;
  }
}

/// Queries downlevel capability flags from the [adapter].
///
/// On native (wgpu), reads the adapter's downlevel flags via FFI.
GpuDownlevel queryDownlevel(GpuAdapter adapter) {
  final wgpuAdapter = adapter as WgpuAdapter;
  final bits = wgpuAdapter.downlevelFlags;
  final flags = <GpuCapability>{};
  for (final entry in _downlevelBits.entries) {
    if (bits & entry.value != 0) flags.add(entry.key);
  }
  return GpuDownlevel(flags);
}

/// Queries active workarounds for the [adapter].
///
/// On native (wgpu), determines workarounds from the adapter's vendor ID
/// and device string. Renderers should check these flags to avoid known
/// broken code paths.
GpuWorkarounds queryWorkarounds(GpuAdapter adapter) =>
    blocklist.workaroundsFor((adapter as WgpuAdapter).info);
