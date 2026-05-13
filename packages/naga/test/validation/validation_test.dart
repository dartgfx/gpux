import 'package:naga/naga.dart';
import 'package:test/test.dart';

import '../support/shaders.dart';

void main() {
  group('Naga.validate', () {
    test('validates WGSL source', () {
      final errors = Naga.validate(NagaSource.wgsl(wgslVertex));

      expect(errors, isEmpty);
    });

    test('keeps String validation as WGSL compatibility path', () {
      final errors = Naga.validate(wgslVertex);

      expect(errors, isEmpty);
    });

    test('reports WGSL semantic errors', () {
      final errors = Naga.validate(NagaSource.wgsl(wgslInvalidSemantic));

      expect(errors, isNotEmpty);
      expect(errors.first.message, contains('invalid_function'));
    });

    test('reports WGSL syntax error locations', () {
      final errors = Naga.validate(NagaSource.wgsl(wgslSyntaxError));

      expect(errors, isNotEmpty);
      expect(errors.first.offset, isNotNull);
      expect(errors.first.length, isNotNull);
    });

    test('validates GLSL source with explicit stage', () {
      final errors = Naga.validate(
        NagaSource.glsl(
          glslVertex,
          stage: NagaShaderStage.vertex,
        ),
      );

      expect(errors, isEmpty);
    });

    test('validates GLSL source with defines', () {
      final errors = Naga.validate(
        NagaSource.glsl(
          glslDefinesFragment,
          stage: NagaShaderStage.fragment,
          defines: const {
            'COLOR_R': '1.0',
            'USE_WARM_COLOR': '1',
          },
        ),
      );

      expect(errors, isEmpty);
    });

    test('reports GLSL syntax errors', () {
      final errors = Naga.validate(
        NagaSource.glsl(
          glslSyntaxError,
          stage: NagaShaderStage.vertex,
        ),
      );

      expect(errors, isNotEmpty);
      expect(errors.first.message, isNotEmpty);
    });

    test('reports missing GLSL defines', () {
      final errors = Naga.validate(
        NagaSource.glsl(
          glslDefinesFragment,
          stage: NagaShaderStage.fragment,
        ),
      );

      expect(errors, isNotEmpty);
      expect(errors.first.message, contains('COLOR_R'));
    });

    test('validates SPIR-V source words', () {
      final errors = Naga.validate(NagaSource.spirv(spirvVertexWords));

      expect(errors, isEmpty);
    });

    test('reports malformed SPIR-V words', () {
      final errors = Naga.validate(NagaSource.spirv(malformedSpirvWords));

      expect(errors, isNotEmpty);
      expect(errors.first.message, isNotEmpty);
    });
  });
}
