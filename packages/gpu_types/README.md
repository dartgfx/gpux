# gpu_types

Type markers for GPU-compatible scalars, vectors, and matrices. No data, just shape and size metadata.

```dart
import 'package:gpu_types/gpu_types.dart';

const type = GpuVec3();
type.elementCount;   // 3
type.bytesPerElement; // 4
type.bytes;           // 12
```

Scalars: `GpuF32`, `GpuI32`, `GpuU32`, `GpuU16`, `GpuI16`, `GpuU8`, `GpuI8`

Vectors: `GpuVec2`, `GpuVec3`, `GpuVec4` (f32)

Matrices: `GpuMat2`, `GpuMat3`, `GpuMat4` (f32)
