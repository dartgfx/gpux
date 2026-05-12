// ignore_for_file: depend_on_referenced_packages

import 'package:hooks/hooks.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    await const RustBuilder(
      assetName: 'wgpu_native',
      cratePath: 'native',
    ).run(input: input, output: output);
  });
}
