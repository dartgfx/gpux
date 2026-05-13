import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../model/entry_point.dart';
import '../model/target.dart';
import 'stage.dart';

const _targetWgsl = 0;
const _targetSpirv = 1;
const _targetMsl = 2;
const _targetHlsl = 3;
const _targetGlsl = 4;

const _bit0 = 1 << 0;
const _bit1 = 1 << 1;
const _bit2 = 1 << 2;
const _bit3 = 1 << 3;
const _bit4 = 1 << 4;
const _bit5 = 1 << 5;

final class NativeEntryPoint {
  NativeEntryPoint._({
    required this.stage,
    required this.namePointer,
    required this.nameLength,
  });

  factory NativeEntryPoint.from(
    NagaEntryPoint? entryPoint,
    Allocator allocator,
  ) {
    if (entryPoint == null) {
      return NativeEntryPoint._(
        stage: nativeStageNone,
        namePointer: nullptr,
        nameLength: 0,
      );
    }

    final pointer = entryPoint.name.toNativeUtf8(allocator: allocator);
    return NativeEntryPoint._(
      stage: entryPoint.stage.nativeValue,
      namePointer: pointer.cast(),
      nameLength: pointer.length,
    );
  }

  final int stage;
  final Pointer<Char> namePointer;
  final int nameLength;
}

final class NativeTarget {
  NativeTarget._({
    required this.targetFormat,
    required this.optionFlags,
    required this.optionValue,
  });

  factory NativeTarget.from(NagaTarget target) {
    return switch (target) {
      NagaWgslTarget(:final options) => NativeTarget._(
        targetFormat: _targetWgsl,
        optionFlags: _flags([
          if (options.explicitTypes) _bit0,
        ]),
        optionValue: 0,
      ),
      NagaSpirvTarget(:final options) => NativeTarget._(
        targetFormat: _targetSpirv,
        optionFlags: _flags([
          if (options.debugNames) _bit0,
          if (options.adjustCoordinateSpace) _bit1,
          if (options.labelVaryings) _bit2,
          if (options.forcePointSize) _bit3,
          if (options.clampFragDepth) _bit4,
        ]),
        optionValue: 0,
      ),
      NagaMslTarget(:final options) => NativeTarget._(
        targetFormat: _targetMsl,
        optionFlags: _flags([
          if (options.spirvCrossCompatibility) _bit0,
          if (options.fakeMissingBindings) _bit1,
          if (options.zeroInitializeWorkgroupMemory) _bit2,
          if (options.forceLoopBounding) _bit3,
        ]),
        optionValue: 0,
      ),
      NagaHlslTarget(:final options) => NativeTarget._(
        targetFormat: _targetHlsl,
        optionFlags: _flags([
          if (options.fakeMissingBindings) _bit0,
          if (options.zeroInitializeWorkgroupMemory) _bit1,
          if (options.restrictIndexing) _bit2,
          if (options.forceLoopBounding) _bit3,
          if (options.rayQueryInitializationTracking) _bit4,
        ]),
        optionValue: options.shaderModel.index,
      ),
      NagaGlslTarget(:final options) => NativeTarget._(
        targetFormat: _targetGlsl,
        optionFlags: _flags([
          if (options.adjustCoordinateSpace) _bit0,
          if (options.textureShadowLod) _bit1,
          if (options.drawParameters) _bit2,
          if (options.includeUnusedItems) _bit3,
          if (options.forcePointSize) _bit4,
          if (options.zeroInitializeWorkgroupMemory) _bit5,
        ]),
        optionValue: 0,
      ),
    };
  }

  final int targetFormat;
  final int optionFlags;
  final int optionValue;
}

int _flags(Iterable<int> flags) {
  return flags.fold(0, (result, flag) => result | flag);
}
