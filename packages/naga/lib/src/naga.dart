import 'package:ffi/ffi.dart';

import 'bindings/bindings_generated.dart' as ffi_naga;
import 'bindings/diagnostics.dart';
import 'bindings/output.dart';
import 'bindings/source.dart';
import 'bindings/target.dart';
import 'model/diagnostic.dart';
import 'model/source.dart';
import 'model/target.dart';
import 'model/translation_result.dart';

export 'model/diagnostic.dart';
export 'model/entry_point.dart';
export 'model/options.dart';
export 'model/output.dart';
export 'model/source.dart';
export 'model/target.dart';
export 'model/translation_result.dart';

/// Authoritative shader validation and translation using naga.
abstract final class Naga {
  /// Validate shader source code.
  ///
  /// Returns an empty list if the shader is valid.
  static List<NagaDiagnostic> validate(Object source) {
    return using((arena) {
      final native = NativeSource.from(_coerceSource(source), arena);
      final result = ffi_naga.naga_validate(
        native.textPointer,
        native.textLength,
        native.spirvPointer,
        native.spirvWordCount,
        native.sourceFormat,
        native.glslStage,
        native.glslDefinesPointer,
        native.glslDefineCount,
      );
      try {
        return convertDiagnostics(result.errors, result.error_count);
      } finally {
        ffi_naga.naga_free_validation_result(result);
      }
    });
  }

  /// Translate shader source code to another shader language or binary format.
  static NagaTranslationResult translate(
    NagaSource source, {
    required NagaTarget to,
  }) {
    return using((arena) {
      final native = NativeSource.from(source, arena);
      final nativeTarget = NativeTarget.from(to);
      final nativeEntryPoint = NativeEntryPoint.from(to.entryPoint, arena);
      final result = ffi_naga.naga_translate(
        native.textPointer,
        native.textLength,
        native.spirvPointer,
        native.spirvWordCount,
        native.sourceFormat,
        native.glslStage,
        nativeTarget.targetFormat,
        nativeTarget.optionFlags,
        nativeTarget.optionValue,
        nativeEntryPoint.stage,
        nativeEntryPoint.namePointer,
        nativeEntryPoint.nameLength,
        native.glslDefinesPointer,
        native.glslDefineCount,
      );
      try {
        final diagnostics = convertDiagnostics(
          result.diagnostics,
          result.diagnostic_count,
        );

        if (result.status != 0) {
          return NagaTranslationFailure(diagnostics: diagnostics);
        }

        return NagaTranslationSuccess(
          output: convertOutput(result),
          diagnostics: diagnostics,
        );
      } finally {
        ffi_naga.naga_free_translation_result(result);
      }
    });
  }

  static NagaSource _coerceSource(Object source) {
    return switch (source) {
      NagaSource source => source,
      String source => NagaSource.wgsl(source),
      _ => throw ArgumentError.value(
        source,
        'source',
        'Expected a NagaSource or WGSL source string',
      ),
    };
  }
}
