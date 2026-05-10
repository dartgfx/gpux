import 'dart:convert';
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

  /// Translate GLSL source code to WGSL.
  ///
  /// [defines] are passed to naga's GLSL preprocessor.
  static NagaTranslateResult translateGlslToWgsl(
    String source,
    NagaShaderStage stage, {
    Map<String, String> defines = const {},
  }) {
    final sourceUtf8 = source.toNativeUtf8();
    final definesUtf8 = jsonEncode(defines).toNativeUtf8();

    try {
      final result = ffi_naga.naga_glsl_to_wgsl(
        sourceUtf8.cast(),
        stage.index,
        definesUtf8.cast(),
      );
      try {
        return _convertTranslateResult(result);
      } finally {
        ffi_naga.naga_free_translate_result(result);
      }
    } finally {
      calloc.free(definesUtf8);
      calloc.free(sourceUtf8);
    }
  }

  static List<NagaError> _convertResult(ffi_naga.NagaValidationResult result) {
    return _convertErrors(result.error_count, result.errors);
  }

  static NagaTranslateResult _convertTranslateResult(
    ffi_naga.NagaTranslateResult result,
  ) {
    final errors = _convertErrors(result.error_count, result.errors);
    final wgsl = result.wgsl == nullptr
        ? null
        : result.wgsl.cast<Utf8>().toDartString();
    return NagaTranslateResult(wgsl: wgsl, errors: errors);
  }

  static List<NagaError> _convertErrors(
    int errorCount,
    Pointer<ffi_naga.NagaError> errorsPtr,
  ) {
    if (errorCount == 0) {
      return const [];
    }

    final errors = <NagaError>[];
    for (var i = 0; i < errorCount; i++) {
      final errorFfi = errorsPtr[i];
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

/// GLSL shader stage passed to naga.
enum NagaShaderStage { vertex, fragment, compute }

/// Result of GLSL to WGSL translation.
class NagaTranslateResult {
  /// Translated WGSL, or null when translation failed.
  final String? wgsl;

  /// Translation errors.
  final List<NagaError> errors;

  const NagaTranslateResult({required this.wgsl, required this.errors});

  bool get isSuccess => errors.isEmpty && wgsl != null;
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

  const NagaError({required this.message, this.offset, this.length});

  @override
  String toString() {
    if (offset != null) {
      return 'NagaError: $message (at offset $offset)';
    }
    return 'NagaError: $message';
  }
}
