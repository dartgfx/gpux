import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'src/ffi/bindings_generated.dart' as ffi;

export 'src/ffi/bindings_generated.dart';
export 'src/ffi/enum_ffi.dart' show textureFormatFromFfi;
export 'src/resource.dart' show WgpuResource;

/// Get the last FFI error message, or null if no error.
String? wgpuLastError() {
  final ptr = ffi.wgpu_get_last_error();
  if (ptr == nullptr) return null;
  return ptr.cast<Utf8>().toDartString();
}
