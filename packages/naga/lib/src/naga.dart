import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'ffi/bindings_generated.dart' as ffi_naga;

/// Authoritative WGSL validation using naga.
///
/// naga is the shader compiler used by wgpu - validation results match
/// exactly what wgpu would accept or reject.
abstract final class Naga {
  /// Validate WGSL source code.
  ///
  /// Returns an empty list if the shader is valid.
  /// Returns a list of errors if validation fails.
  ///
  /// ```dart
  /// final errors = Naga.validate('''
  ///   @vertex
  ///   fn main() -> @builtin(position) vec4f {
  ///     return vec4f(0.0);
  ///   }
  /// ''');
  ///
  /// if (errors.isEmpty) {
  ///   print('Shader is valid!');
  /// }
  /// ```
  static List<NagaError> validate(String source) {
    final sourceUtf8 = source.toNativeUtf8();

    try {
      final result = ffi_naga.naga_validate_wgsl(
        sourceUtf8.cast(),
        sourceUtf8.length,
      );
      try {
        return _convertResult(result);
      } finally {
        ffi_naga.naga_free_validation_result(result);
      }
    } finally {
      calloc.free(sourceUtf8);
    }
  }

  static List<NagaError> _convertResult(ffi_naga.NagaValidationResult result) {
    if (result.error_count == 0) {
      return const [];
    }

    final errors = <NagaError>[];
    for (var i = 0; i < result.error_count; i++) {
      final errorFfi = result.errors[i];
      errors.add(
        NagaError(
          message: errorFfi.message.cast<Utf8>().toDartString(),
          offset: errorFfi.offset >= 0 ? errorFfi.offset : null,
          length: errorFfi.length >= 0 ? errorFfi.length : null,
        ),
      );
    }
    return errors;
  }
}

/// A validation error from naga.
class NagaError {
  /// Human-readable error message.
  final String message;

  /// Byte offset into the source where the error occurred.
  /// Null if location is not available.
  final int? offset;

  /// Length of the error span in bytes.
  /// Null if length is not available.
  final int? length;

  const NagaError({
    required this.message,
    this.offset,
    this.length,
  });

  @override
  String toString() {
    if (offset != null) {
      return 'NagaError: $message (at offset $offset)';
    }
    return 'NagaError: $message';
  }
}
