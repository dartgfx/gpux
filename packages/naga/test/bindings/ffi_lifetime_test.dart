import 'package:naga/naga.dart';
import 'package:test/test.dart';

import '../support/shaders.dart';

void main() {
  group('FFI lifetime', () {
    const iterations = 25;

    test('repeatedly validates all source buffer shapes', () {
      for (var i = 0; i < iterations; i++) {
        expect(Naga.validate(NagaSource.wgsl(wgslVertex)), isEmpty);
        expect(
          Naga.validate(
            NagaSource.glsl(glslVertex, stage: NagaShaderStage.vertex),
          ),
          isEmpty,
        );
        expect(Naga.validate(NagaSource.spirv(spirvVertexWords)), isEmpty);
      }
    });

    test('repeatedly translates text and binary outputs', () {
      for (var i = 0; i < iterations; i++) {
        expectTextOutput(
          Naga.translate(
            NagaSource.wgsl(wgslVertex),
            to: const NagaTarget.wgsl(),
          ),
        );
        expectSpirvOutput(
          Naga.translate(
            NagaSource.wgsl(wgslVertex),
            to: const NagaTarget.spirv(
              entryPoint: NagaEntryPoint.vertex('main'),
            ),
          ),
        );
        expectTextOutput(
          Naga.translate(
            NagaSource.spirv(spirvVertexWords),
            to: const NagaTarget.hlsl(
              entryPoint: NagaEntryPoint.vertex('main'),
            ),
          ),
        );
      }
    });

    test('repeatedly copies diagnostics before native result is freed', () {
      for (var i = 0; i < iterations; i++) {
        final errors = Naga.validate(NagaSource.wgsl(wgslInvalidSemantic));

        expect(errors, isNotEmpty);
        expect(errors.first.message, contains('invalid_function'));
      }
    });
  });
}
