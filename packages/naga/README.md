# naga

Shader validation and translation for Dart using [naga](https://github.com/gfx-rs/naga), the shader compiler behind wgpu.

## Usage

```dart
import 'package:naga/naga.dart';

final errors = Naga.validate(NagaSource.wgsl(wgslSource));
if (errors.isEmpty) {
  print('Shader is valid');
} else {
  for (final e in errors) {
    print('${e.message} at offset ${e.offset}');
  }
}
```

Translate between supported naga formats:

```dart
final result = Naga.translate(
  NagaSource.wgsl(wgslSource),
  to: const NagaTarget.spirv(
    entryPoint: NagaEntryPoint.vertex('main'),
    options: NagaSpirvOptions(debugNames: true),
  ),
);

switch (result) {
  case NagaTranslationSuccess(output: final NagaSpirvOutput output):
    print('Generated ${output.words.length} SPIR-V words');
  case NagaTranslationSuccess(output: final output):
    print(output);
  case NagaTranslationFailure(:final diagnostics):
    for (final diagnostic in diagnostics) {
      print(diagnostic);
    }
}
```

GLSL sources must include the shader stage because GLSL source text does not
carry one reliably:

```dart
final result = Naga.translate(
  NagaSource.glsl(
    glslSource,
    stage: NagaShaderStage.fragment,
    defines: const {'USE_LIGHTING': '1'},
  ),
  to: const NagaTarget.wgsl(),
);
```

SPIR-V sources are passed as 32-bit words:

```dart
final result = Naga.translate(
  NagaSource.spirv(spirvWords),
  to: const NagaTarget.glsl(
    entryPoint: NagaEntryPoint.vertex('main'),
  ),
);
```

## Supported formats

Naga parses WGSL, GLSL, and SPIR-V sources. It emits WGSL, SPIR-V, Metal
Shading Language, HLSL, and GLSL targets.

| Source | Target | Notes |
| --- | --- | --- |
| WGSL | WGSL | Whole-module text output. |
| WGSL | SPIR-V | Entry point is optional. Provide one to emit a pipeline-specific module. |
| WGSL | MSL | Entry point is optional. |
| WGSL | HLSL | Entry point is optional. |
| WGSL | GLSL | Entry point is required. |
| GLSL | WGSL | GLSL source requires an explicit shader stage. |
| GLSL | SPIR-V | GLSL source requires an explicit shader stage. |
| GLSL | MSL | GLSL source requires an explicit shader stage. |
| GLSL | HLSL | GLSL source requires an explicit shader stage. |
| GLSL | GLSL | GLSL source requires a stage; GLSL output requires an entry point. |
| SPIR-V | WGSL | SPIR-V source is passed as 32-bit words. |
| SPIR-V | SPIR-V | Re-emits SPIR-V words after parsing and validation. |
| SPIR-V | MSL | SPIR-V source is passed as 32-bit words. |
| SPIR-V | HLSL | SPIR-V source is passed as 32-bit words. |
| SPIR-V | GLSL | GLSL output requires an entry point. |

MSL and HLSL are output-only formats in this package because naga does not
provide MSL or HLSL frontends.
