import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../model/output.dart';
import 'bindings_generated.dart' as ffi_naga;

const _outputText = 1;
const _outputSpirv = 2;

NagaOutput convertOutput(ffi_naga.NagaTranslationResult result) {
  return switch (result.output_kind) {
    _outputText => _convertTextOutput(result),
    _outputSpirv => _convertSpirvOutput(result),
    _ => throw StateError('Unknown naga output kind: ${result.output_kind}'),
  };
}

NagaTextOutput _convertTextOutput(ffi_naga.NagaTranslationResult result) {
  if (result.output_text == nullptr) {
    throw StateError('Naga returned text output with a null pointer');
  }
  return NagaTextOutput(result.output_text.cast<Utf8>().toDartString());
}

NagaSpirvOutput _convertSpirvOutput(ffi_naga.NagaTranslationResult result) {
  if (result.output_word_count == 0) {
    return NagaSpirvOutput(Uint32List(0));
  }
  if (result.output_word_count > 0 && result.output_words == nullptr) {
    throw StateError(
      'Naga returned ${result.output_word_count} SPIR-V words '
      'with a null pointer',
    );
  }
  return NagaSpirvOutput(
    Uint32List.fromList(
      result.output_words.asTypedList(result.output_word_count),
    ),
  );
}
