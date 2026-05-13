import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../model/source.dart';
import 'bindings_generated.dart' as ffi_naga;
import 'stage.dart';

const _sourceWgsl = 0;
const _sourceGlsl = 1;
const _sourceSpirv = 2;

final class NativeSource {
  NativeSource._({
    required this.textPointer,
    required this.textLength,
    required this.spirvPointer,
    required this.spirvWordCount,
    required this.sourceFormat,
    required this.glslStage,
    required this.glslDefinesPointer,
    required this.glslDefineCount,
  });

  factory NativeSource.from(NagaSource source, Allocator allocator) {
    return switch (source) {
      NagaWgslSource(:final source) => NativeSource._text(
        source,
        allocator: allocator,
        sourceFormat: _sourceWgsl,
        glslStage: nativeStageNone,
      ),
      NagaGlslSource(:final source, :final stage, :final defines) =>
        NativeSource._text(
          source,
          allocator: allocator,
          sourceFormat: _sourceGlsl,
          glslStage: stage.nativeValue,
          glslDefines: NativeGlslDefines.from(defines, allocator),
        ),
      NagaSpirvSource(:final words) => NativeSource._spirv(words, allocator),
    };
  }

  factory NativeSource._text(
    String source, {
    required Allocator allocator,
    required int sourceFormat,
    required int glslStage,
    NativeGlslDefines? glslDefines,
  }) {
    final pointer = source.toNativeUtf8(allocator: allocator);
    final defines = glslDefines ?? NativeGlslDefines.empty();
    return NativeSource._(
      textPointer: pointer.cast(),
      textLength: pointer.length,
      spirvPointer: nullptr,
      spirvWordCount: 0,
      sourceFormat: sourceFormat,
      glslStage: glslStage,
      glslDefinesPointer: defines.pointer,
      glslDefineCount: defines.count,
    );
  }

  factory NativeSource._spirv(Uint32List words, Allocator allocator) {
    final pointer = allocator<Uint32>(words.length);
    pointer.asTypedList(words.length).setAll(0, words);
    return NativeSource._(
      textPointer: nullptr,
      textLength: 0,
      spirvPointer: pointer,
      spirvWordCount: words.length,
      sourceFormat: _sourceSpirv,
      glslStage: nativeStageNone,
      glslDefinesPointer: nullptr,
      glslDefineCount: 0,
    );
  }

  final Pointer<Char> textPointer;
  final int textLength;
  final Pointer<Uint32> spirvPointer;
  final int spirvWordCount;
  final int sourceFormat;
  final int glslStage;
  final Pointer<ffi_naga.NagaGlslDefine> glslDefinesPointer;
  final int glslDefineCount;
}

final class NativeGlslDefines {
  NativeGlslDefines._({
    required this.pointer,
    required this.count,
  });

  factory NativeGlslDefines.empty() {
    return NativeGlslDefines._(pointer: nullptr, count: 0);
  }

  factory NativeGlslDefines.from(
    Map<String, String> defines,
    Allocator allocator,
  ) {
    if (defines.isEmpty) {
      return NativeGlslDefines.empty();
    }

    final pointer = allocator<ffi_naga.NagaGlslDefine>(defines.length);
    var index = 0;
    for (final entry in defines.entries) {
      final name = entry.key.toNativeUtf8(allocator: allocator);
      final value = entry.value.toNativeUtf8(allocator: allocator);
      pointer[index]
        ..name = name.cast()
        ..name_len = name.length
        ..value = value.cast()
        ..value_len = value.length;
      index++;
    }

    return NativeGlslDefines._(
      pointer: pointer,
      count: defines.length,
    );
  }

  final Pointer<ffi_naga.NagaGlslDefine> pointer;
  final int count;
}
