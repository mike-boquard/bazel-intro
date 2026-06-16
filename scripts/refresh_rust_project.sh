#!/usr/bin/env bash
# Regenerates rust-project.json for rust-analyzer IDE support.
#
# Run this script after adding new rust_library / rust_binary targets so that
# rust-analyzer can resolve crate imports and provide completions.
#
# The generated rust-project.json is placed at the workspace root, where
# rust-analyzer finds it automatically (or via the linkedProjects VSCode setting).
#
# --- Why we strip the `sysroot` field ---
# gen_rust_project sets `sysroot` to Bazel's hermetic Rust toolchain directory.
# That directory contains rustc but NOT cargo.  rust-analyzer uses the `sysroot`
# path to locate cargo, which it calls as `cargo metadata --lockfile-path ...`
# (a flag that requires cargo ≥ 1.82).  When cargo is absent, rustup falls back
# to the system stable toolchain whose cargo may be older, producing:
#   "unexpected argument '--lockfile-path' found"
# Removing `sysroot` avoids that cargo call entirely.  `sysroot_src` is kept so
# rust-analyzer can still offer std / core / alloc completions.  For rustc itself
# (proc-macro expansion) rust-analyzer falls back to whichever rustc is in PATH.
#
# Docs: https://github.com/bazelbuild/rules_rust/blob/main/tools/rust_analyzer/README.md
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
bazel run @rules_rust//tools/rust_analyzer:gen_rust_project
python3 - <<'EOF'
import json, pathlib
p = pathlib.Path("rust-project.json")
d = json.loads(p.read_text())
d.pop("sysroot", None)
p.write_text(json.dumps(d, indent=2) + "\n")
print("rust-project.json written (sysroot field stripped)")
EOF
