import 'dart:typed_data';

/// Translated shader output.
sealed class NagaOutput {
  /// Creates translated shader output.
  const NagaOutput();
}

/// Text shader output.
final class NagaTextOutput extends NagaOutput {
  /// Creates text shader output.
  const NagaTextOutput(this.source);

  /// The translated source text.
  final String source;
}

/// SPIR-V word output.
final class NagaSpirvOutput extends NagaOutput {
  /// Creates SPIR-V word output.
  const NagaSpirvOutput(this.words);

  /// The translated SPIR-V words.
  final Uint32List words;
}
