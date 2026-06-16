#!/usr/bin/env bash
# Regenerates rust-project.json for rust-analyzer IDE support.
#
# Run this script after adding new rust_library / rust_binary targets so that
# rust-analyzer can resolve crate imports and provide completions.
#
# The generated rust-project.json is placed at the workspace root, where
# rust-analyzer finds it automatically (or via the linkedProjects VSCode setting).
#
# Docs: https://github.com/bazelbuild/rules_rust/blob/main/tools/rust_analyzer/README.md
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
bazel run @rules_rust//tools/rust_analyzer:gen_rust_project
