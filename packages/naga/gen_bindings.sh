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
cbindgen --config cbindgen.toml --output include/naga_native.h
cd ..

echo "==> Generating Dart bindings from C header..."
if command -v fvm >/dev/null 2>&1; then
  fvm dart run ffigen --config ffigen.yaml
else
  dart run ffigen --config ffigen.yaml
fi

echo "==> Formatting generated file..."
if command -v fvm >/dev/null 2>&1; then
  fvm dart format lib/src/bindings/bindings_generated.dart
else
  dart format lib/src/bindings/bindings_generated.dart
fi

echo "==> Done! Generated:"
echo "    native/include/naga_native.h"
echo "    lib/src/bindings/bindings_generated.dart"
