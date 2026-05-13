import 'package:naga/naga.dart';
import 'package:test/test.dart';

void main() {
  group('API shape', () {
    test('stores source-specific GLSL stage', () {
      const source = NagaSource.glsl(
        'void main() {}',
        stage: NagaShaderStage.fragment,
      );

      const glsl = source as NagaGlslSource;
      expect(glsl.stage, NagaShaderStage.fragment);
    });

    test('stores target-specific entry point', () {
      const target = NagaTarget.glsl(
        entryPoint: NagaEntryPoint.fragment('main'),
      );

      const glsl = target as NagaGlslTarget;
      expect(glsl.entryPoint.stage, NagaShaderStage.fragment);
      expect(glsl.entryPoint.name, 'main');
    });

    test('keeps optional entry point optional on whole-module targets', () {
      const target = NagaTarget.wgsl();

      expect(target.entryPoint, isNull);
    });

    test('stores target-specific options', () {
      const target = NagaTarget.hlsl(
        options: NagaHlslOptions(shaderModel: NagaHlslShaderModel.v6_0),
      );

      const hlsl = target as NagaHlslTarget;
      expect(hlsl.options.shaderModel, NagaHlslShaderModel.v6_0);
    });
  });
}
