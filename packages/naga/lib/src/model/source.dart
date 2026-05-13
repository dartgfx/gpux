import 'dart:typed_data';

import 'entry_point.dart';

/// Shader source accepted by naga.
sealed class NagaSource {
  const NagaSource();

  /// WGSL source text.
  const factory NagaSource.wgsl(String source) = NagaWgslSource;

  /// GLSL source text.
  ///
  /// GLSL does not carry a reliable shader stage in the same way WGSL does, so
  /// callers must provide the stage expected by the pipeline.
  const factory NagaSource.glsl(
    String source, {
    required NagaShaderStage stage,
    Map<String, String> defines,
  }) = NagaGlslSource;

  /// SPIR-V words.
  const factory NagaSource.spirv(Uint32List words) = NagaSpirvSource;
}

/// WGSL source text.
final class NagaWgslSource extends NagaSource {
  /// Creates WGSL source text.
  const NagaWgslSource(this.source);

  /// The WGSL source text.
  final String source;
}

/// GLSL source text.
final class NagaGlslSource extends NagaSource {
  /// Creates GLSL source text.
  const NagaGlslSource(
    this.source, {
    required this.stage,
    this.defines = const {},
  });

  /// The GLSL source text.
  final String source;

  /// The shader stage for this GLSL source.
  final NagaShaderStage stage;

  /// Preprocessor definitions passed to naga's GLSL frontend.
  final Map<String, String> defines;
}

/// SPIR-V source words.
final class NagaSpirvSource extends NagaSource {
  /// Creates SPIR-V source words.
  const NagaSpirvSource(this.words);

  /// The SPIR-V words.
  final Uint32List words;
}
