import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:gpuweb/gpuweb.dart';

import 'ffi/bindings_generated.dart' as ffi;
import 'resource.dart';

/// A compiled shader module.
class WgpuShaderModule extends WgpuNativeResource implements GpuShaderModule {
  static final _fin = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
      ffi.wgpun_ShaderModuleRelease_p,
    ),
  );

  @override
  String label;

  WgpuShaderModule.internal(int handle, {this.label = ''})
    : super(handle, _fin);

  int get handle => nativeHandle;

  @override
  NativeFinalizer get finalizer => _fin;
  @override
  void release(int handle) => ffi.wgpun_ShaderModuleRelease(handle);

  @override
  Future<List<GpuCompilationMessage>> getCompilationInfo() async {
    final ptr = ffi.wgpun_ShaderModuleGetCompilationInfo(nativeHandle);
    if (ptr == nullptr) return const [];

    final raw = ptr.cast<Utf8>().toDartString();
    final lines = raw.split('\n');
    return [
      for (final line in lines)
        if (line.isNotEmpty) _parseMessage(line),
    ];
  }

  static GpuCompilationMessage _parseMessage(String line) {
    final parts = line.split('\t');
    final type = switch (parts[0]) {
      'E' => GpuCompilationMessageType.error,
      'W' => GpuCompilationMessageType.warning,
      _ => GpuCompilationMessageType.info,
    };
    final lineNum = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final linePos = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    final message = parts.length > 3 ? parts[3] : '';
    return GpuCompilationMessage(
      message: message,
      type: type,
      lineNum: lineNum,
      linePos: linePos,
    );
  }
}
