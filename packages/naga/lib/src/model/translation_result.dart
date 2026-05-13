import 'diagnostic.dart';
import 'output.dart';

/// Result of shader translation.
sealed class NagaTranslationResult {
  /// Creates a translation result.
  const NagaTranslationResult();
}

/// Successful shader translation.
final class NagaTranslationSuccess extends NagaTranslationResult {
  /// Creates a successful translation result.
  const NagaTranslationSuccess({
    required this.output,
    this.diagnostics = const [],
  });

  /// The translated output.
  final NagaOutput output;

  /// Non-fatal diagnostics emitted during translation.
  final List<NagaDiagnostic> diagnostics;
}

/// Failed shader translation.
final class NagaTranslationFailure extends NagaTranslationResult {
  /// Creates a failed translation result.
  const NagaTranslationFailure({
    required this.diagnostics,
  });

  /// Diagnostics explaining the failure.
  final List<NagaDiagnostic> diagnostics;
}
