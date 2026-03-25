import 'adapter.dart';
import 'texture.dart';

/// Power preference when requesting an adapter.
///
/// See [WebGPU spec: GPUPowerPreference](https://www.w3.org/TR/webgpu/#enumdef-gpupowerpreference).
enum GpuPowerPreference {
  /// Prefer low power consumption (integrated GPU).
  lowPower,

  /// Prefer high performance (discrete GPU).
  highPerformance,
}

/// Options for requesting an adapter.
///
/// See [WebGPU spec: GPURequestAdapterOptions](https://www.w3.org/TR/webgpu/#dictdef-gpurequestadapteroptions).
class GpuRequestAdapterOptions {
  /// Creates adapter request options.
  const GpuRequestAdapterOptions({
    this.featureLevel = 'core',
    this.powerPreference,
    this.forceFallbackAdapter = false,
  });

  /// The feature level required ("core" or "compatibility").
  final String featureLevel;

  /// Power preference hint for adapter selection.
  final GpuPowerPreference? powerPreference;

  /// If true, only a software/fallback adapter may be returned.
  final bool forceFallbackAdapter;
}

/// WGSL language feature names.
///
/// See [WebGPU spec: WGSLLanguageFeatures](https://www.w3.org/TR/webgpu/#wgsllanguagefeatures).
enum GpuWgslLanguageFeatureName {
  /// Read-only and read-write storage textures.
  readonlyAndReadwriteStorageTextures,

  /// Packed 4x8 integer dot product instructions.
  packed4x8IntegerDotProduct,

  /// Unrestricted pointer parameters in functions.
  unrestrictedPointerParameters,

  /// Pointer composite access (member/index through pointers).
  pointerCompositeAccess,

  /// std140 layout for uniform buffers.
  uniformBufferStandardLayout,

  /// Subgroup ID and size builtins.
  subgroupId,

  /// `let` declarations for textures and samplers.
  textureAndSamplerLet,

  /// Subgroup uniformity analysis.
  subgroupUniformity,
}

/// A GPU instance — entry point for GPU access.
///
/// See [WebGPU spec: GPU](https://www.w3.org/TR/webgpu/#gpu-interface).
abstract interface class GpuInstance {
  /// Returns the optimal texture format for displaying 8-bit depth,
  /// standard dynamic range content on this system.
  ///
  /// Must only return [GpuTextureFormat.rgba8Unorm] or
  /// [GpuTextureFormat.bgra8Unorm].
  ///
  /// See [WebGPU spec: getPreferredCanvasFormat()](https://www.w3.org/TR/webgpu/#dom-gpu-getpreferredcanvasformat).
  GpuTextureFormat get preferredCanvasFormat;

  /// WGSL language features supported by this instance.
  Set<GpuWgslLanguageFeatureName> get wgslLanguageFeatures;

  /// Request an adapter from this instance.
  Future<GpuAdapter> requestAdapter([
    GpuRequestAdapterOptions options = const GpuRequestAdapterOptions(),
  ]);
}
