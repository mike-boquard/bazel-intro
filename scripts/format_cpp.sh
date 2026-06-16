#!/usr/bin/env bash
# Formats all C++ source files using clang-format 18.1.8 from the BCR-downloaded
# LLVM toolchain.  No system clang-format required.
#
# Style is defined in .clang-format at the workspace root.
# Run once after making C++ changes; also useful as a pre-commit check:
#   ./scripts/format_cpp.sh && git diff --exit-code
#
# Usage:
#   ./scripts/format_cpp.sh          # format in-place
#   ./scripts/format_cpp.sh --check  # exit 1 if any file would change
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

CHECK=0
if [[ "${1:-}" == "--check" ]]; then
    CHECK=1
fi

WORKSPACE=$(pwd)
abs_files=()
while IFS= read -r f; do abs_files+=("$WORKSPACE/$f"); done < <(find cpp/ -type f \( -name "*.cc" -o -name "*.h" \) | sort)

if (( CHECK )); then
    bazel run @llvm_toolchain//:clang-format -- --dry-run --Werror "${abs_files[@]}"
    echo "clang-format check passed (${#abs_files[@]} files)"
else
    bazel run @llvm_toolchain//:clang-format -- -i "${abs_files[@]}"
    echo "Formatted ${#abs_files[@]} C++ files"
fi
