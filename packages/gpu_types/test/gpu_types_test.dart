import 'package:gpu_types/gpu_types.dart';
import 'package:test/test.dart';

void main() {
  group('scalars', () {
    final cases = [
      (type: const GpuF32(), bytes: 4, name: 'GpuF32'),
      (type: const GpuI32(), bytes: 4, name: 'GpuI32'),
      (type: const GpuU32(), bytes: 4, name: 'GpuU32'),
      (type: const GpuU16(), bytes: 2, name: 'GpuU16'),
      (type: const GpuI16(), bytes: 2, name: 'GpuI16'),
      (type: const GpuU8(), bytes: 1, name: 'GpuU8'),
      (type: const GpuI8(), bytes: 1, name: 'GpuI8'),
    ];
    for (final c in cases) {
      test('${c.name} is ${c.bytes} byte(s)', () {
        expect(c.type.elementCount, 1);
        expect(c.type.columnCount, 1);
        expect(c.type.bytesPerElement, c.bytes);
        expect(c.type.bytes, c.bytes);
      });
    }
  });

  group('vectors', () {
    final cases = [
      (type: const GpuVec2(), elements: 2, bytes: 8),
      (type: const GpuVec3(), elements: 3, bytes: 12),
      (type: const GpuVec4(), elements: 4, bytes: 16),
    ];
    for (final c in cases) {
      test(
          'GpuVec${c.elements} has ${c.elements} elements and ${c.bytes} bytes',
          () {
        expect(c.type.elementCount, c.elements);
        expect(c.type.bytesPerElement, 4);
        expect(c.type.bytes, c.bytes);
        expect(c.type.columnCount, 1);
      });
    }
  });

  group('matrices', () {
    final cases = [
      (type: const GpuMat2(), elements: 4, cols: 2, bytes: 16),
      (type: const GpuMat3(), elements: 9, cols: 3, bytes: 36),
      (type: const GpuMat4(), elements: 16, cols: 4, bytes: 64),
    ];
    for (final c in cases) {
      test(
          'GpuMat${c.cols} has ${c.elements} elements, ${c.cols} columns, ${c.bytes} bytes',
          () {
        expect(c.type.elementCount, c.elements);
        expect(c.type.columnCount, c.cols);
        expect(c.type.bytesPerElement, 4);
        expect(c.type.bytes, c.bytes);
      });
    }
  });
}
