import 'object_base.dart';

/// Compilation message severity.
///
/// See [WebGPU spec: GPUCompilationMessageType](https://www.w3.org/TR/webgpu/#enumdef-gpucompilationmessagetype).
enum GpuCompilationMessageType {
  /// A compilation error.
  error,

  /// A compilation warning.
  warning,

  /// An informational message.
  info,
}

/// A message from shader compilation.
///
/// See [WebGPU spec: GPUCompilationMessage](https://www.w3.org/TR/webgpu/#gpucompilationmessage).
class GpuCompilationMessage {
  /// Creates a compilation message.
  const GpuCompilationMessage({
    required this.message,
    required this.type,
    required this.lineNum,
    required this.linePos,
    this.offset = 0,
    this.length = 0,
  });

  /// The message text.
  final String message;

  /// The severity of the message.
  final GpuCompilationMessageType type;

  /// The line number (1-based).
  final int lineNum;

  /// The column position within the line (1-based).
  final int linePos;

  /// Byte offset into the shader source.
  final int offset;

  /// Length of the relevant source range in bytes.
  final int length;

  @override
  String toString() => '${type.name}($lineNum:$linePos): $message';
}

/// A compiled shader module.
///
/// See [WebGPU spec: GPUShaderModule](https://www.w3.org/TR/webgpu/#gpushadermodule).
abstract interface class GpuShaderModule implements GpuObjectBase {
  /// Returns compilation messages (errors, warnings, info).
  Future<List<GpuCompilationMessage>> getCompilationInfo();
}
