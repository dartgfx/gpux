import 'adapter.dart';
import 'bind_group.dart';
import 'buffer.dart';
import 'encoder.dart';
import 'pipeline.dart';
import 'query_set.dart';
import 'queue.dart';
import 'sampler.dart';
import 'shader.dart';
import 'texture.dart';

/// A logical GPU device for creating resources.
///
/// See [WebGPU spec: GPUDevice](https://www.w3.org/TR/webgpu/#gpudevice).
abstract interface class GpuDevice {
  /// Features enabled on this device.
  Set<GpuFeatureName> get features;

  /// Limits for this device.
  GpuLimits get limits;

  /// Information about the adapter this device was created from.
  GpuAdapterInfo get adapterInfo;

  /// The command queue for this device.
  GpuQueue get queue;

  /// Creates a GPU buffer.
  GpuBuffer createBuffer({
    required int size,
    required GpuBufferUsageFlags usage,
    bool mappedAtCreation = false,
    String label = '',
  });

  /// Creates a texture.
  GpuTexture createTexture({
    required int width,
    int height = 1,
    int depthOrArrayLayers = 1,
    int mipLevelCount = 1,
    int sampleCount = 1,
    GpuTextureDimension dimension = GpuTextureDimension.d2,
    required GpuTextureFormat format,
    required GpuTextureUsageFlags usage,
    List<GpuTextureFormat> viewFormats = const [],
    GpuTextureViewDimension? textureBindingViewDimension,
    String label = '',
  });

  /// Creates a sampler.
  GpuSampler createSampler({
    GpuAddressMode addressModeU = GpuAddressMode.clampToEdge,
    GpuAddressMode addressModeV = GpuAddressMode.clampToEdge,
    GpuAddressMode addressModeW = GpuAddressMode.clampToEdge,
    GpuFilterMode magFilter = GpuFilterMode.nearest,
    GpuFilterMode minFilter = GpuFilterMode.nearest,
    GpuMipmapFilterMode mipmapFilter = GpuMipmapFilterMode.nearest,
    double lodMinClamp = 0.0,
    double lodMaxClamp = 32.0,
    int maxAnisotropy = 1,
    GpuCompareFunction? compare,
    String label = '',
  });

  /// Creates a shader module from WGSL source.
  GpuShaderModule createShaderModule(String wgslSource, {String label = ''});

  /// Creates a command encoder.
  GpuCommandEncoder createCommandEncoder({String label = ''});

  /// Creates a query set.
  GpuQuerySet createQuerySet({
    required GpuQueryType type,
    required int count,
    String label = '',
  });

  /// Creates a bind group layout.
  GpuBindGroupLayout createBindGroupLayout(
    List<GpuBindGroupLayoutEntry> entries, {
    String label = '',
  });

  /// Creates a bind group.
  GpuBindGroup createBindGroup({
    required GpuBindGroupLayout layout,
    required List<GpuBindGroupEntry> entries,
    String label = '',
  });

  /// Creates a pipeline layout.
  ///
  /// Null entries in [layouts] represent unused bind group slots
  GpuPipelineLayout createPipelineLayout(
    List<GpuBindGroupLayout?> layouts, {
    String label = '',
  });

  /// Creates a compute pipeline.
  GpuComputePipeline createComputePipeline({
    required GpuShaderModule module,
    String? entryPoint,
    Map<String, double> constants = const {},
    required GpuPipelineLayout? layout,
    String label = '',
  });

  /// Creates a render pipeline.
  GpuRenderPipeline createRenderPipeline(
    GpuRenderPipelineDescriptor descriptor,
  );

  /// Creates a compute pipeline asynchronously.
  Future<GpuComputePipeline> createComputePipelineAsync({
    required GpuShaderModule module,
    String? entryPoint,
    Map<String, double> constants = const {},
    required GpuPipelineLayout? layout,
    String label = '',
  });

  /// Creates a render bundle encoder.
  GpuRenderBundleEncoder createRenderBundleEncoder(
    GpuRenderBundleEncoderDescriptor descriptor,
  );

  /// Creates a render pipeline asynchronously.
  Future<GpuRenderPipeline> createRenderPipelineAsync(
    GpuRenderPipelineDescriptor descriptor,
  );

  /// Completes when the device is lost.
  Future<GpuDeviceLostInfo> get lost;

  /// Pushes an error scope onto the error scope stack.
  void pushErrorScope(GpuErrorFilter filter);

  /// Pops the top error scope and resolves to any captured error.
  Future<GpuError?> popErrorScope();

  /// Errors not captured by any error scope.
  Stream<GpuError> get onUncapturedError;

  /// Destroys the device.
  void destroy();
}

/// Reason for device loss.
///
/// See [WebGPU spec: GPUDeviceLostReason](https://www.w3.org/TR/webgpu/#enumdef-gpudevicelostreason).
enum GpuDeviceLostReason {
  /// Device was lost for an unknown reason.
  unknown,

  /// Device was explicitly destroyed.
  destroyed,
}

/// Information about a device loss event.
///
/// See [WebGPU spec: GPUDeviceLostInfo](https://www.w3.org/TR/webgpu/#gpudevicelostinfo).
class GpuDeviceLostInfo {
  /// Creates device lost info.
  const GpuDeviceLostInfo({required this.reason, this.message = ''});

  /// Why the device was lost.
  final GpuDeviceLostReason reason;

  /// Human-readable message about the loss.
  final String message;
}

/// Error filter for error scopes.
///
/// See [WebGPU spec: GPUErrorFilter](https://www.w3.org/TR/webgpu/#enumdef-gpuerrorfilter).
enum GpuErrorFilter {
  /// Captures validation errors.
  validation,

  /// Captures out-of-memory errors.
  outOfMemory,

  /// Captures internal errors.
  internal,
}

/// A GPU error captured by an error scope.
///
/// See [WebGPU spec: GPUError](https://www.w3.org/TR/webgpu/#gpuerror).
sealed class GpuError {
  /// Creates a GPU error.
  const GpuError(this.message);

  /// The error message.
  final String message;
}

/// A validation error.
class GpuValidationError extends GpuError {
  /// Creates a validation error.
  const GpuValidationError(super.message);
}

/// An out-of-memory error.
class GpuOutOfMemoryError extends GpuError {
  /// Creates an out-of-memory error.
  const GpuOutOfMemoryError(super.message);
}

/// An internal error.
class GpuInternalError extends GpuError {
  /// Creates an internal error.
  const GpuInternalError(super.message);
}
