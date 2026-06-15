# Bazel File Comments + clangd Integration Design

**Date:** 2026-06-15
**Status:** Approved

## Goals

1. Make every Bazel file self-explanatory for a reader learning Bazel for the first time.
2. Fix IDE C++ diagnostics (false "header not found" errors) by generating `compile_commands.json` via hedron_compile_commands.

---

## Part 1: Bazel File Comments

### Style

- **Block comment** at the top of every Bazel file explaining its purpose and linking to official docs.
- **Inline comments** within a file only when a single attribute or label needs clarification (e.g., `gtest_main`, `visibility = ["//visibility:public"]`, label syntax like `@abseil-cpp//absl/strings`).
- `MODULE.bazel` gets a block comment before each logical grouping because it covers multiple distinct concepts in one file.

### Files and doc links

| File | Block comment covers | Docs link |
|------|---------------------|-----------|
| `MODULE.bazel` | Each stanza group: Bzlmod basics, BCR C++ deps, non-BCR extension, Go toolchain, go_deps | https://bazel.build/external/module |
| `BUILD.bazel` (root) | Why the root package must exist | https://bazel.build/concepts/build-files |
| `third_party/BUILD.bazel` | Package marker for label resolution | https://bazel.build/concepts/labels |
| `third_party/extensions.bzl` | What a module extension is; how http_archive pulls non-BCR deps | https://bazel.build/external/extension |
| `third_party/spdlog.BUILD` | Header-only cc_library pattern; SPDLOG_HEADER_ONLY define | https://bazel.build/reference/be/c-cpp#cc_library |
| `cpp/greeter/BUILD.bazel` | cc_library + cc_test; BCR dep label syntax | https://bazel.build/reference/be/c-cpp |
| `cpp/app/BUILD.bazel` | cc_binary | https://bazel.build/reference/be/c-cpp#cc_binary |
| `go/greeter/BUILD.bazel` | go_library + go_test; importpath | https://github.com/bazelbuild/rules_go/blob/main/docs/go/core/rules.md |
| `go/app/BUILD.bazel` | go_binary | same as above |

---

## Part 2: hedron_compile_commands (clangd integration)

### Why

The IDE clangd language server doesn't know Bazel's workspace-rooted include paths. Running `hedron_compile_commands` generates a `compile_commands.json` at the workspace root that clangd reads, eliminating all false "header not found" diagnostics.

### Approach

`hedron_compile_commands` is **not in the BCR** — making it a natural second example of the non-BCR dependency pattern already demonstrated with spdlog.

### Changes

**`third_party/extensions.bzl`** — add a second `http_archive` block for `hedron_compile_commands` alongside spdlog inside the same `_non_registry_deps_impl` function.

**`MODULE.bazel`** — extend existing `use_repo`:
```starlark
use_repo(non_registry, "spdlog", "hedron_compile_commands")
```

**`BUILD.bazel` (root)** — add target:
```python
load("@hedron_compile_commands//:refresh_compile_commands.bzl", "refresh_compile_commands")

refresh_compile_commands(
    name = "refresh_compile_commands",
    targets = {"//cpp/...": ""},
)
```

**`scripts/refresh_compile_commands.sh`** — convenience wrapper:
```bash
#!/usr/bin/env bash
# Regenerates compile_commands.json for C++ clangd support.
# Re-run after adding or modifying C++ source files.
set -euo pipefail
bazel run //:refresh_compile_commands
```

### Usage after setup

```bash
./scripts/refresh_compile_commands.sh
# or directly:
bazel run //:refresh_compile_commands
```

This produces `compile_commands.json` at the workspace root. clangd finds it automatically.
