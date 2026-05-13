import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../model/diagnostic.dart';
import 'bindings_generated.dart' as ffi_naga;

List<NagaDiagnostic> convertDiagnostics(
  Pointer<ffi_naga.NagaError> diagnostics,
  int count,
) {
  if (count == 0) {
    return const [];
  }
  if (diagnostics == nullptr) {
    throw StateError('Naga returned $count diagnostics with a null pointer');
  }

  final errors = <NagaDiagnostic>[];
  for (var i = 0; i < count; i++) {
    final errorFfi = diagnostics[i];
    if (errorFfi.message == nullptr) {
      throw StateError('Naga returned diagnostic $i with a null message');
    }
    errors.add(
      NagaDiagnostic(
        message: errorFfi.message.cast<Utf8>().toDartString(),
        offset: errorFfi.offset >= 0 ? errorFfi.offset : null,
        length: errorFfi.length >= 0 ? errorFfi.length : null,
      ),
    );
  }
  return errors;
}
