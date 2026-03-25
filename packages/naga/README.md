# naga

WGSL validation for Dart using [naga](https://github.com/gfx-rs/naga), the shader compiler behind wgpu. Validation results match exactly what wgpu accepts or rejects.

## Usage

```dart
import 'package:naga/naga.dart';

final errors = Naga.validate(wgslSource);
if (errors.isEmpty) {
  print('Shader is valid');
} else {
  for (final e in errors) {
    print('${e.message} at offset ${e.offset}');
  }
}
```

Uses Dart Native Assets — the Rust library builds automatically, no manual setup.
