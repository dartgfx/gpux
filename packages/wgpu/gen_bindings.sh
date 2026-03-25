#!/bin/bash
# Generate FFI bindings from Rust source
#
# Run this when you add/change FFI functions in native/src/lib.rs
# Requires: cargo install cbindgen

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Generating C header from Rust..."
cd native
cbindgen --config cbindgen.toml --output include/wgpu_native.h
cd ..

echo "==> Generating Dart bindings from C header..."
dart run ffigen --config ffigen.yaml

echo "==> Formatting generated file..."
dart format lib/src/ffi/bindings_generated.dart

echo "==> Done! Generated:"
echo "    native/include/wgpu_native.h"
echo "    lib/src/ffi/bindings_generated.dart"
