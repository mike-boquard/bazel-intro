#!/usr/bin/env bash
# Regenerates compile_commands.json for C++ clangd support.
#
# Run this script after adding or modifying C++ source files so that
# clangd can resolve includes like "cpp/greeter/greeter.h".
#
# The generated compile_commands.json is placed at the workspace root,
# where clangd finds it automatically.
#
# Docs: https://github.com/hedronvision/bazel-compile-commands-extractor
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
bazel run //:refresh_compile_commands
