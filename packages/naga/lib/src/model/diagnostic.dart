/// A diagnostic from naga.
final class NagaDiagnostic {
  /// Creates a naga diagnostic.
  const NagaDiagnostic({
    required this.message,
    this.offset,
    this.length,
  });

  /// Human-readable message.
  final String message;

  /// Byte offset into the source, when available.
  final int? offset;

  /// Byte length of the source span, when available.
  final int? length;

  @override
  String toString() {
    if (offset case final offset?) {
      return 'NagaDiagnostic: $message (at offset $offset)';
    }
    return 'NagaDiagnostic: $message';
  }
}

/// Backwards-compatible name for validation diagnostics.
typedef NagaError = NagaDiagnostic;
