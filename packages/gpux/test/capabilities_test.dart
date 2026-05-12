import 'package:gpux/gpux.dart';
import 'package:test/test.dart';

void main() {
  group('GpuDownlevel', () {
    test('reports supported capabilities', () {
      const downlevel = GpuDownlevel({
        GpuCapability.computeShaders,
        GpuCapability.vertexStorage,
      });
      expect(downlevel.supports(GpuCapability.computeShaders), isTrue);
      expect(downlevel.supports(GpuCapability.vertexStorage), isTrue);
      expect(downlevel.supports(GpuCapability.indirectExecution), isFalse);
      expect(downlevel.supports(GpuCapability.anisotropicFiltering), isFalse);
    });

    test('empty set reports nothing supported', () {
      const downlevel = GpuDownlevel({});
      for (final cap in GpuCapability.values) {
        expect(downlevel.supports(cap), isFalse);
      }
    });

    test('full set reports everything supported', () {
      final downlevel = GpuDownlevel(GpuCapability.values.toSet());
      for (final cap in GpuCapability.values) {
        expect(downlevel.supports(cap), isTrue);
      }
    });
  });

  group('GpuWorkarounds', () {
    test('none has no workarounds', () {
      expect(GpuWorkarounds.none.brokenMipmapGeneration, isFalse);
    });

    test('can enable broken mipmap generation', () {
      const w = GpuWorkarounds(brokenMipmapGeneration: true);
      expect(w.brokenMipmapGeneration, isTrue);
    });
  });
}
