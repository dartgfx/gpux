// ignore_for_file: depend_on_referenced_packages

import 'package:hooks/hooks.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    await const RustBuilder(
      // Just the asset name - native_toolchain_rust adds the package prefix
      assetName: 'wgpu_native',
      // Rust crate is in the 'native' directory
      cratePath: 'native',
    ).run(input: input, output: output);
  });
}
