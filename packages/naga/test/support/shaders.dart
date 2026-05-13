import 'dart:io';
import 'dart:typed_data';

import 'package:naga/naga.dart';
import 'package:test/test.dart';

String fixtureText(String relativePath) {
  final candidates = [
    'test/fixtures/$relativePath',
    'packages/naga/test/fixtures/$relativePath',
  ];

  for (final candidate in candidates) {
    final file = File(candidate);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }

  throw StateError('Missing naga test fixture: $relativePath');
}

List<String> fixtureLines(String relativePath) {
  return fixtureText(relativePath)
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

Uint32List fixtureSpirvWords(String relativePath) {
  return Uint32List.fromList(
    fixtureLines(relativePath).map(int.parse).toList(),
  );
}

final wgslVertex = fixtureText('wgsl/vertex.wgsl');
final wgslFragment = fixtureText('wgsl/fragment.wgsl');
final wgslInvalidSemantic = fixtureText('wgsl/invalid_semantic.wgsl');
final wgslSyntaxError = fixtureText('wgsl/syntax_error.wgsl');
final glslVertex = fixtureText('glsl/vertex.vert');
final glslFragment = fixtureText('glsl/fragment.frag');
final glslDefinesFragment = fixtureText('glsl/defines.frag');
final glslSyntaxError = fixtureText('glsl/syntax_error.vert');
final spirvVertexWords = fixtureSpirvWords('spirv/vertex.words');
final malformedSpirvWords = Uint32List.fromList([0x07230203, 0, 0, 0]);

final mslVertexSnippets = fixtureLines('targets/msl_vertex.contains');
final hlslVertexSnippets = fixtureLines('targets/hlsl_vertex.contains');
final glslFragmentSnippets = fixtureLines('targets/glsl_fragment.contains');

NagaTranslationSuccess expectTranslationSuccess(NagaTranslationResult result) {
  expect(result, isA<NagaTranslationSuccess>());
  return result as NagaTranslationSuccess;
}

NagaTranslationFailure expectTranslationFailure(NagaTranslationResult result) {
  expect(result, isA<NagaTranslationFailure>());
  return result as NagaTranslationFailure;
}

NagaTextOutput expectTextOutput(NagaTranslationResult result) {
  final success = expectTranslationSuccess(result);
  expect(success.output, isA<NagaTextOutput>());
  return success.output as NagaTextOutput;
}

NagaSpirvOutput expectSpirvOutput(NagaTranslationResult result) {
  final success = expectTranslationSuccess(result);
  expect(success.output, isA<NagaSpirvOutput>());
  final output = success.output as NagaSpirvOutput;
  expect(output.words, isNotEmpty);
  expect(output.words.first, 0x07230203);
  return output;
}

void expectContainsAll(String source, Iterable<String> snippets) {
  for (final snippet in snippets) {
    expect(source, contains(snippet));
  }
}
