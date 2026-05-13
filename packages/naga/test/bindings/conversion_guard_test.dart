import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:naga/src/bindings/bindings_generated.dart' as ffi_naga;
import 'package:naga/src/bindings/diagnostics.dart';
import 'package:naga/src/bindings/output.dart';
import 'package:test/test.dart';

void main() {
  group('FFI conversion guards', () {
    test('rejects text output with null pointer', () {
      final result = calloc<ffi_naga.NagaTranslationResult>();
      try {
        result.ref
          ..output_kind = 1
          ..output_text = nullptr;

        expect(() => convertOutput(result.ref), throwsStateError);
      } finally {
        calloc.free(result);
      }
    });

    test('rejects SPIR-V output with nonzero count and null pointer', () {
      final result = calloc<ffi_naga.NagaTranslationResult>();
      try {
        result.ref
          ..output_kind = 2
          ..output_words = nullptr
          ..output_word_count = 1;

        expect(() => convertOutput(result.ref), throwsStateError);
      } finally {
        calloc.free(result);
      }
    });

    test('rejects unknown output kind', () {
      final result = calloc<ffi_naga.NagaTranslationResult>();
      try {
        result.ref.output_kind = 99;

        expect(() => convertOutput(result.ref), throwsStateError);
      } finally {
        calloc.free(result);
      }
    });

    test('rejects diagnostics with null array pointer', () {
      expect(
        () => convertDiagnostics(nullptr, 1),
        throwsStateError,
      );
    });

    test('rejects diagnostic with null message pointer', () {
      final diagnostics = calloc<ffi_naga.NagaError>();
      try {
        diagnostics.ref
          ..message = nullptr
          ..offset = -1
          ..length = -1;

        expect(
          () => convertDiagnostics(diagnostics, 1),
          throwsStateError,
        );
      } finally {
        calloc.free(diagnostics);
      }
    });
  });
}
