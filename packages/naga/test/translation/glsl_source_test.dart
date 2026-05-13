import 'package:naga/naga.dart';
import 'package:test/test.dart';

import '../support/shaders.dart';

void main() {
  group('GLSL source translation', () {
    test('translates vertex GLSL to WGSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.glsl(
            glslVertex,
            stage: NagaShaderStage.vertex,
          ),
          to: const NagaTarget.wgsl(),
        ),
      );

      expect(output.source, contains('@vertex'));
      expect(output.source, contains('fn main'));
    });

    test('translates fragment GLSL to WGSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.glsl(
            glslFragment,
            stage: NagaShaderStage.fragment,
          ),
          to: const NagaTarget.wgsl(),
        ),
      );

      expect(output.source, contains('@fragment'));
      expect(output.source, contains('fn main'));
    });

    test('translates GLSL with defines to WGSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.glsl(
            glslDefinesFragment,
            stage: NagaShaderStage.fragment,
            defines: const {
              'COLOR_R': '1.0',
              'USE_WARM_COLOR': '1',
            },
          ),
          to: const NagaTarget.wgsl(),
        ),
      );

      expect(output.source, contains('@fragment'));
      expect(output.source, contains('fn main'));
      expect(output.source, contains('0.25'));
    });

    test('translates vertex GLSL to SPIR-V words', () {
      expectSpirvOutput(
        Naga.translate(
          NagaSource.glsl(
            glslVertex,
            stage: NagaShaderStage.vertex,
          ),
          to: const NagaTarget.spirv(
            entryPoint: NagaEntryPoint.vertex('main'),
          ),
        ),
      );
    });

    test('translates vertex GLSL to MSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.glsl(
            glslVertex,
            stage: NagaShaderStage.vertex,
          ),
          to: const NagaTarget.msl(
            entryPoint: NagaEntryPoint.vertex('main'),
          ),
        ),
      );

      expectContainsAll(output.source, mslVertexSnippets);
    });

    test('translates vertex GLSL to HLSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.glsl(
            glslVertex,
            stage: NagaShaderStage.vertex,
          ),
          to: const NagaTarget.hlsl(
            entryPoint: NagaEntryPoint.vertex('main'),
          ),
        ),
      );

      expectContainsAll(output.source, hlslVertexSnippets);
    });

    test('translates fragment GLSL to GLSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.glsl(
            glslFragment,
            stage: NagaShaderStage.fragment,
          ),
          to: const NagaTarget.glsl(
            entryPoint: NagaEntryPoint.fragment('main'),
          ),
        ),
      );

      expectContainsAll(output.source, glslFragmentSnippets);
    });

    test('applies GLSL writer options', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.glsl(
            glslVertex,
            stage: NagaShaderStage.vertex,
          ),
          to: const NagaTarget.glsl(
            entryPoint: NagaEntryPoint.vertex('main'),
            options: NagaGlslOptions(forcePointSize: true),
          ),
        ),
      );

      expect(output.source, contains('gl_PointSize'));
    });

    test('returns diagnostics for invalid GLSL', () {
      final failure = expectTranslationFailure(
        Naga.translate(
          NagaSource.glsl(
            glslSyntaxError,
            stage: NagaShaderStage.vertex,
          ),
          to: const NagaTarget.wgsl(),
        ),
      );

      expect(failure.diagnostics, isNotEmpty);
      expect(failure.diagnostics.first.message, isNotEmpty);
    });

    test('returns diagnostics for missing GLSL defines', () {
      final failure = expectTranslationFailure(
        Naga.translate(
          NagaSource.glsl(
            glslDefinesFragment,
            stage: NagaShaderStage.fragment,
          ),
          to: const NagaTarget.wgsl(),
        ),
      );

      expect(failure.diagnostics, isNotEmpty);
      expect(failure.diagnostics.first.message, contains('COLOR_R'));
    });
  });
}
