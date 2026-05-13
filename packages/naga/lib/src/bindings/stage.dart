import '../model/entry_point.dart';

const nativeStageNone = -1;
const _stageVertex = 0;
const _stageFragment = 1;
const _stageCompute = 2;

extension NativeShaderStage on NagaShaderStage {
  int get nativeValue {
    return switch (this) {
      NagaShaderStage.vertex => _stageVertex,
      NagaShaderStage.fragment => _stageFragment,
      NagaShaderStage.compute => _stageCompute,
    };
  }
}
