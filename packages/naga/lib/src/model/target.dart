import 'entry_point.dart';
import 'options.dart';

/// Shader translation target.
sealed class NagaTarget {
  const NagaTarget();

  /// WGSL text output.
  const factory NagaTarget.wgsl({
    NagaWgslOptions options,
  }) = NagaWgslTarget;

  /// SPIR-V word output.
  const factory NagaTarget.spirv({
    NagaEntryPoint? entryPoint,
    NagaSpirvOptions options,
  }) = NagaSpirvTarget;

  /// Metal Shading Language text output.
  const factory NagaTarget.msl({
    NagaEntryPoint? entryPoint,
    NagaMslOptions options,
  }) = NagaMslTarget;

  /// HLSL text output.
  const factory NagaTarget.hlsl({
    NagaEntryPoint? entryPoint,
    NagaHlslOptions options,
  }) = NagaHlslTarget;

  /// GLSL text output.
  const factory NagaTarget.glsl({
    required NagaEntryPoint entryPoint,
    NagaGlslOptions options,
  }) = NagaGlslTarget;

  NagaEntryPoint? get entryPoint;
}

/// WGSL translation target.
final class NagaWgslTarget extends NagaTarget {
  /// Creates a WGSL translation target.
  const NagaWgslTarget({
    this.options = const NagaWgslOptions(),
  });

  /// WGSL writer options.
  final NagaWgslOptions options;

  @override
  NagaEntryPoint? get entryPoint => null;
}

/// SPIR-V translation target.
final class NagaSpirvTarget extends NagaTarget {
  /// Creates a SPIR-V translation target.
  const NagaSpirvTarget({
    this.entryPoint,
    this.options = const NagaSpirvOptions(),
  });

  /// Entry point to emit, or null to let naga emit the whole module.
  @override
  final NagaEntryPoint? entryPoint;

  /// SPIR-V writer options.
  final NagaSpirvOptions options;
}

/// MSL translation target.
final class NagaMslTarget extends NagaTarget {
  /// Creates an MSL translation target.
  const NagaMslTarget({
    this.entryPoint,
    this.options = const NagaMslOptions(),
  });

  /// Entry point to emit, or null to let naga emit all entry points.
  @override
  final NagaEntryPoint? entryPoint;

  /// MSL writer options.
  final NagaMslOptions options;
}

/// HLSL translation target.
final class NagaHlslTarget extends NagaTarget {
  /// Creates an HLSL translation target.
  const NagaHlslTarget({
    this.entryPoint,
    this.options = const NagaHlslOptions(),
  });

  /// Entry point to emit, or null to let naga emit all entry points.
  @override
  final NagaEntryPoint? entryPoint;

  /// HLSL writer options.
  final NagaHlslOptions options;
}

/// GLSL translation target.
final class NagaGlslTarget extends NagaTarget {
  /// Creates a GLSL translation target.
  const NagaGlslTarget({
    required this.entryPoint,
    this.options = const NagaGlslOptions(),
  });

  /// Entry point to emit.
  @override
  final NagaEntryPoint entryPoint;

  /// GLSL writer options.
  final NagaGlslOptions options;
}
