import 'package:naga/naga.dart';
import 'package:test/test.dart';

void main() {
  // With Native Assets, library loading is automatic - no setup needed!

  group('Naga.validate', () {
    test('valid shader returns empty errors', () {
      const validShader = '''
@vertex
fn main() -> @builtin(position) vec4f {
  return vec4f(0.0, 0.0, 0.0, 1.0);
}
''';
      final errors = Naga.validate(validShader);
      expect(errors, isEmpty);
    });

    test('invalid shader returns errors', () {
      const invalidShader = '''
@vertex
fn main() -> @builtin(position) vec4f {
  return invalid_function();
}
''';
      final errors = Naga.validate(invalidShader);
      expect(errors, isNotEmpty);
      expect(errors.first.message, contains('invalid_function'));
    });

    test('syntax error returns error with location', () {
      const syntaxError = '''
@vertex
fn main( {
  return vec4f(0.0);
}
''';
      final errors = Naga.validate(syntaxError);
      expect(errors, isNotEmpty);
      // Should have offset info for syntax errors
      expect(errors.first.offset, isNotNull);
    });
  });
}
