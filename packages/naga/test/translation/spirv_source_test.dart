import 'package:naga/naga.dart';
import 'package:test/test.dart';

import '../support/shaders.dart';

void main() {
  group('SPIR-V source translation', () {
    test('translates to WGSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.spirv(spirvVertexWords),
          to: const NagaTarget.wgsl(),
        ),
      );

      expect(output.source, contains('@vertex'));
      expect(output.source, contains('fn main'));
    });

    test('round-trips to SPIR-V words', () {
      expectSpirvOutput(
        Naga.translate(
          NagaSource.spirv(spirvVertexWords),
          to: const NagaTarget.spirv(
            entryPoint: NagaEntryPoint.vertex('main'),
          ),
        ),
      );
    });

    test('translates to MSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.spirv(spirvVertexWords),
          to: const NagaTarget.msl(
            entryPoint: NagaEntryPoint.vertex('main'),
          ),
        ),
      );

      expectContainsAll(output.source, mslVertexSnippets);
    });

    test('translates to HLSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.spirv(spirvVertexWords),
          to: const NagaTarget.hlsl(
            entryPoint: NagaEntryPoint.vertex('main'),
          ),
        ),
      );

      expectContainsAll(output.source, hlslVertexSnippets);
    });

    test('translates to GLSL text', () {
      final output = expectTextOutput(
        Naga.translate(
          NagaSource.spirv(spirvVertexWords),
          to: const NagaTarget.glsl(
            entryPoint: NagaEntryPoint.vertex('main'),
          ),
        ),
      );

      expect(output.source, contains('#version'));
      expect(output.source, contains('void main'));
    });

    test('returns diagnostics for missing entry point', () {
      final failure = expectTranslationFailure(
        Naga.translate(
          NagaSource.spirv(spirvVertexWords),
          to: const NagaTarget.hlsl(
            entryPoint: NagaEntryPoint.vertex('missing'),
          ),
        ),
      );

      expect(failure.diagnostics, isNotEmpty);
      expect(failure.diagnostics.first.message, contains('missing'));
    });

    test('returns diagnostics for malformed SPIR-V words', () {
      final failure = expectTranslationFailure(
        Naga.translate(
          NagaSource.spirv(malformedSpirvWords),
          to: const NagaTarget.wgsl(),
        ),
      );

      expect(failure.diagnostics, isNotEmpty);
      expect(failure.diagnostics.first.message, isNotEmpty);
    });
  });
}
