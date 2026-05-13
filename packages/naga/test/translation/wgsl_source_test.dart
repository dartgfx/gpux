import 'package:naga/naga.dart';
import 'package:test/test.dart';

import '../support/shaders.dart';

void main() {
  group('WGSL source translation', () {
    test('translates to WGSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.wgsl(wgslVertex),
          to: const NagaTarget.wgsl(),
        ),
      );

      expect(output.source, contains('@vertex'));
      expect(output.source, contains('fn main'));
    });

    test('applies WGSL writer options', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.wgsl(wgslVertex),
          to: const NagaTarget.wgsl(
            options: NagaWgslOptions(explicitTypes: true),
          ),
        ),
      );

      expect(output.source, contains('vec4<f32>'));
    });

    test('translates to SPIR-V words', () {
      expectSpirvOutput(
        Naga.translate(
          NagaSource.wgsl(wgslVertex),
          to: const NagaTarget.spirv(
            entryPoint: NagaEntryPoint.vertex('main'),
          ),
        ),
      );
    });

    test('applies SPIR-V writer options', () {
      final defaultOutput = expectSpirvOutput(
        Naga.translate(
          NagaSource.wgsl(wgslVertex),
          to: const NagaTarget.spirv(
            entryPoint: NagaEntryPoint.vertex('main'),
          ),
        ),
      );
      final pointSizeOutput = expectSpirvOutput(
        Naga.translate(
          NagaSource.wgsl(wgslVertex),
          to: const NagaTarget.spirv(
            entryPoint: NagaEntryPoint.vertex('main'),
            options: NagaSpirvOptions(forcePointSize: true),
          ),
        ),
      );

      expect(
        pointSizeOutput.words.toList(),
        isNot(defaultOutput.words.toList()),
      );
    });

    test('translates to MSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.wgsl(wgslVertex),
          to: const NagaTarget.msl(
            entryPoint: NagaEntryPoint.vertex('main'),
          ),
        ),
      );

      expectContainsAll(output.source, mslVertexSnippets);
    });

    test('applies MSL writer options', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.wgsl(wgslVertex),
          to: const NagaTarget.msl(
            entryPoint: NagaEntryPoint.vertex('main'),
            options: NagaMslOptions(spirvCrossCompatibility: true),
          ),
        ),
      );

      expectContainsAll(output.source, mslVertexSnippets);
    });

    test('translates to HLSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.wgsl(wgslVertex),
          to: const NagaTarget.hlsl(
            entryPoint: NagaEntryPoint.vertex('main'),
          ),
        ),
      );

      expectContainsAll(output.source, hlslVertexSnippets);
    });

    test('applies HLSL writer options', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.wgsl(wgslVertex),
          to: const NagaTarget.hlsl(
            entryPoint: NagaEntryPoint.vertex('main'),
            options: NagaHlslOptions(shaderModel: NagaHlslShaderModel.v6_0),
          ),
        ),
      );

      expectContainsAll(output.source, hlslVertexSnippets);
    });

    test('translates to GLSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.wgsl(wgslFragment),
          to: const NagaTarget.glsl(
            entryPoint: NagaEntryPoint.fragment('main'),
          ),
        ),
      );

      expectContainsAll(output.source, glslFragmentSnippets);
    });

    test('returns diagnostics for invalid WGSL', () {
      final failure = expectTranslationFailure(
        Naga.translate(
          NagaSource.wgsl(wgslInvalidSemantic),
          to: const NagaTarget.wgsl(),
        ),
      );

      expect(failure.diagnostics, isNotEmpty);
      expect(failure.diagnostics.first.message, contains('invalid_function'));
    });
  });
}
