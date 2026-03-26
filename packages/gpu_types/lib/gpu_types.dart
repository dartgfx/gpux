/// Base marker for all GPU-compatible types.
abstract interface class GpuType {
  /// Number of elements.
  int get elementCount;

  /// Number of columns (1 for scalars and vectors).
  int get columnCount;

  /// Bytes per element.
  int get bytesPerElement;

  /// Total size in bytes.
  int get bytes;
}

/// Marker for GPU-compatible scalar types.
abstract class GpuScalar implements GpuType {
  const GpuScalar();

  @override
  int get elementCount => 1;

  @override
  int get columnCount => 1;

  @override
  int get bytes => bytesPerElement;
}

/// 32-bit floating point.
class GpuF32 extends GpuScalar {
  const GpuF32();

  @override
  int get bytesPerElement => 4;
}

/// 32-bit signed integer.
class GpuI32 extends GpuScalar {
  const GpuI32();

  @override
  int get bytesPerElement => 4;
}

/// 32-bit unsigned integer.
class GpuU32 extends GpuScalar {
  const GpuU32();

  @override
  int get bytesPerElement => 4;
}

/// 16-bit unsigned integer.
class GpuU16 extends GpuScalar {
  const GpuU16();

  @override
  int get bytesPerElement => 2;
}

/// 16-bit signed integer.
class GpuI16 extends GpuScalar {
  const GpuI16();

  @override
  int get bytesPerElement => 2;
}

/// 8-bit unsigned integer.
class GpuU8 extends GpuScalar {
  const GpuU8();

  @override
  int get bytesPerElement => 1;
}

/// 8-bit signed integer.
class GpuI8 extends GpuScalar {
  const GpuI8();

  @override
  int get bytesPerElement => 1;
}

/// 2-component f32 vector.
class GpuVec2 implements GpuType {
  const GpuVec2();

  @override
  int get elementCount => 2;

  @override
  int get columnCount => 1;

  @override
  int get bytesPerElement => 4;

  @override
  int get bytes => elementCount * bytesPerElement;
}

/// 3-component f32 vector.
class GpuVec3 implements GpuType {
  const GpuVec3();

  @override
  int get elementCount => 3;

  @override
  int get columnCount => 1;

  @override
  int get bytesPerElement => 4;

  @override
  int get bytes => elementCount * bytesPerElement;
}

/// 4-component f32 vector.
class GpuVec4 implements GpuType {
  const GpuVec4();

  @override
  int get elementCount => 4;

  @override
  int get columnCount => 1;

  @override
  int get bytesPerElement => 4;

  @override
  int get bytes => elementCount * bytesPerElement;
}

/// 2x2 f32 matrix (4 elements).
class GpuMat2 implements GpuType {
  const GpuMat2();

  @override
  int get elementCount => 4;

  @override
  int get columnCount => 2;

  @override
  int get bytesPerElement => 4;

  @override
  int get bytes => elementCount * bytesPerElement;
}

/// 3x3 f32 matrix (9 elements).
class GpuMat3 implements GpuType {
  const GpuMat3();

  @override
  int get elementCount => 9;

  @override
  int get columnCount => 3;

  @override
  int get bytesPerElement => 4;

  @override
  int get bytes => elementCount * bytesPerElement;
}

/// 4x4 f32 matrix (16 elements).
class GpuMat4 implements GpuType {
  const GpuMat4();

  @override
  int get elementCount => 16;

  @override
  int get columnCount => 4;

  @override
  int get bytesPerElement => 4;

  @override
  int get bytes => elementCount * bytesPerElement;
}
