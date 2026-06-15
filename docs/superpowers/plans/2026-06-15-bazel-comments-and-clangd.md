# Bazel Comments + clangd Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add educational block comments (with doc links) to every Bazel file, and wire up `hedron_compile_commands` so `bazel run //:refresh_compile_commands` generates `compile_commands.json` for clangd.

**Architecture:** Two sequential tasks. Task 1 is pure comment editing — no functional change. Task 2 adds `hedron_compile_commands` as a second non-BCR dep (via the existing module extension in `third_party/extensions.bzl`), adds a `refresh_compile_commands` target to the root `BUILD.bazel`, and creates a convenience shell script.

**Tech Stack:** Bazel 7.4.1, Bzlmod, hedron_compile_commands (non-BCR), clangd

---

## File Map

| File | Task | Change |
|------|------|--------|
| `MODULE.bazel` | 1 + 2 | Task 1: add section block comments. Task 2: update `use_repo` to add `hedron_compile_commands` |
| `third_party/BUILD.bazel` | 1 | Add block comment explaining the package marker |
| `third_party/extensions.bzl` | 1 + 2 | Task 1: add block comment + inline comments. Task 2: add hedron `http_archive` block |
| `third_party/spdlog.BUILD` | 1 | Add block comment explaining header-only pattern |
| `cpp/greeter/BUILD.bazel` | 1 | Add block comment + inline attribute comments |
| `cpp/app/BUILD.bazel` | 1 | Add block comment + inline dep comments |
| `go/greeter/BUILD.bazel` | 1 | Add block comment |
| `go/app/BUILD.bazel` | 1 | Add block comment + inline dep comments |
| `BUILD.bazel` (root) | 2 | Replace stub comment with real block + add `refresh_compile_commands` target |
| `scripts/refresh_compile_commands.sh` | 2 | Create convenience wrapper script |

---

## Task 1: Add Block Comments to All Bazel Files

No functional change — only comments. All tests must still pass after this task.

**Files:**
- Modify: `MODULE.bazel`
- Modify: `third_party/BUILD.bazel`
- Modify: `third_party/extensions.bzl`
- Modify: `third_party/spdlog.BUILD`
- Modify: `cpp/greeter/BUILD.bazel`
- Modify: `cpp/app/BUILD.bazel`
- Modify: `go/greeter/BUILD.bazel`
- Modify: `go/app/BUILD.bazel`

- [ ] **Step 1: Replace `MODULE.bazel` with the commented version**

```starlark
# MODULE.bazel — Bzlmod module definition for this workspace.
#
# Bzlmod is Bazel's modern dependency management system, replacing the legacy
# WORKSPACE file.  Every external dependency is declared here and resolved
# against the Bazel Central Registry (https://registry.bazel.build) unless
# fetched via a module extension.
#
# Docs: https://bazel.build/external/module

module(
    name = "bazel_intro",
    version = "0.0.1",
)

# ── Core utilities ─────────────────────────────────────────────────────────────
# bazel_skylib   — common Starlark helper functions used by many rule sets.
# rules_cc       — cc_library / cc_binary / cc_test rules for C++ targets.
bazel_dep(name = "bazel_skylib", version = "1.7.1")
bazel_dep(name = "rules_cc", version = "0.0.10")

# ── C++ testing and libraries (BCR) ──────────────────────────────────────────
# googletest  — Google's C++ unit testing framework.
#               Referenced in BUILD files as @googletest//:gtest_main.
#               BCR: https://registry.bazel.build/modules/googletest
# abseil-cpp  — Google's C++ utility library (strings, containers, etc.).
#               //cpp/greeter uses absl::StrCat from this module.
#               BCR: https://registry.bazel.build/modules/abseil-cpp
bazel_dep(name = "googletest", version = "1.15.2")
bazel_dep(name = "abseil-cpp", version = "20240722.0")

# ── Non-BCR C++ dependencies (via module extension) ───────────────────────────
# Libraries absent from the BCR are fetched with http_archive() inside a module
# extension defined in //third_party:extensions.bzl.  Each repo name must be
# listed in use_repo() to be visible to targets in the build graph.
non_registry = use_extension("//third_party:extensions.bzl", "non_registry")
use_repo(non_registry, "spdlog")

# ── Go toolchain and rules (BCR) ──────────────────────────────────────────────
# rules_go  — go_library / go_binary / go_test rules and the Go toolchain.
#             BCR: https://registry.bazel.build/modules/rules_go
# gazelle   — generates Bazel BUILD files from Go source and manages go.mod.
#             BCR: https://registry.bazel.build/modules/gazelle
bazel_dep(name = "rules_go", version = "0.50.1")
bazel_dep(name = "gazelle", version = "0.39.1")

# Download the Go SDK.  No separate Go installation is needed — Bazel fetches
# and caches the SDK automatically via bazelisk.
# Docs: https://github.com/bazelbuild/rules_go/blob/main/docs/go/toolchains.md
go_sdk = use_extension("@rules_go//go:extensions.bzl", "go_sdk")
go_sdk.download(version = "1.22.5")

# ── Go module dependencies (via go.mod) ───────────────────────────────────────
# Go packages are NOT distributed through the BCR.  They are declared in
# go.mod using standard Go tooling and fetched from the Go module proxy via
# Gazelle's go_deps module extension.
#
# Workflow for adding a new Go dependency:
#   1. bazel run @rules_go//go -- get <pkg>@<version>
#   2. bazel mod tidy                                    (updates use_repo below)
#   3. bazel run @gazelle//:gazelle -- <pkg-dir>         (regenerates BUILD files)
#
# Docs: https://github.com/bazelbuild/bazel-gazelle/blob/master/docs/go_repository.md
go_deps = use_extension("@gazelle//:extensions.bzl", "go_deps")
go_deps.from_file(go_mod = "//:go.mod")
use_repo(go_deps, "com_github_fatih_color")
```

- [ ] **Step 2: Replace `third_party/BUILD.bazel` with the commented version**

```python
# BUILD.bazel — package marker for the third_party/ directory.
#
# An empty BUILD.bazel makes third_party/ a Bazel package, which is required
# for the labels //third_party:extensions.bzl and //third_party:spdlog.BUILD
# to be valid.  Without this file, those labels would be unresolvable and
# MODULE.bazel's use_extension() call would fail.
#
# Docs: https://bazel.build/concepts/labels
```

- [ ] **Step 3: Replace `third_party/extensions.bzl` with the commented version**

```python
# extensions.bzl — Bzlmod module extension for non-BCR C++ dependencies.
#
# A module extension lets a Bazel module fetch repositories that are not
# listed in the Bazel Central Registry.  This extension uses http_archive()
# to download C++ libraries directly from GitHub releases.
#
# To expose a repo defined here, list it in MODULE.bazel:
#   non_registry = use_extension("//third_party:extensions.bzl", "non_registry")
#   use_repo(non_registry, "<name>")
#
# Docs: https://bazel.build/external/extension
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _non_registry_deps_impl(ctx):
    # spdlog: fast C++ logging library, header-only mode.
    # Not in the BCR, so fetched directly from the GitHub release tarball.
    # build_file injects //third_party:spdlog.BUILD so Bazel can compile it.
    # Docs: https://github.com/gabime/spdlog
    http_archive(
        name = "spdlog",
        url = "https://github.com/gabime/spdlog/archive/refs/tags/v1.14.1.tar.gz",
        sha256 = "1586508029a7d0670dfcb2d97575dcdc242d3868a259742b69f100801ab4e16b",
        strip_prefix = "spdlog-1.14.1",
        build_file = Label("//third_party:spdlog.BUILD"),
    )

non_registry = module_extension(
    implementation = _non_registry_deps_impl,
)
```

- [ ] **Step 4: Replace `third_party/spdlog.BUILD` with the commented version**

```python
# spdlog.BUILD — build rules for the spdlog C++ logging library (non-BCR dep).
#
# This file is injected into the spdlog external repository by extensions.bzl
# via build_file = Label("//third_party:spdlog.BUILD").  Bazel uses it in
# place of any BUILD file that might exist inside the spdlog source tree.
#
# spdlog supports a header-only mode (SPDLOG_HEADER_ONLY) that avoids a
# separate compilation step.  All implementation is included at usage sites,
# which keeps this BUILD file simple: no srcs, just hdrs and a define.
#
# Docs: https://bazel.build/reference/be/c-cpp#cc_library
#       https://github.com/gabime/spdlog/wiki/0.-FAQ
load("@rules_cc//cc:defs.bzl", "cc_library")

cc_library(
    name = "spdlog",
    # Glob all headers from spdlog's include directory.
    hdrs = glob(["include/**/*.h"]),
    # Make #include "spdlog/spdlog.h" resolvable without a path prefix.
    includes = ["include"],
    # Activate header-only mode — disables the precompiled spdlog.cpp.
    defines = ["SPDLOG_HEADER_ONLY"],
    visibility = ["//visibility:public"],
)
```

- [ ] **Step 5: Replace `cpp/greeter/BUILD.bazel` with the commented version**

```python
# BUILD.bazel — C++ greeter library and unit tests.
#
# cc_library compiles greeter.cc into a reusable library target.  It depends
# on abseil-cpp (a BCR module) for the absl::StrCat string utility.
#
# cc_test compiles greeter_test.cc and links it with the greeter library and
# GoogleTest's gtest_main, which supplies main() so the test file itself
# doesn't need one.  Run tests with: bazel test //cpp/greeter:greeter_test
#
# Docs: https://bazel.build/reference/be/c-cpp#cc_library
#       https://bazel.build/reference/be/c-cpp#cc_test
load("@rules_cc//cc:defs.bzl", "cc_library", "cc_test")

cc_library(
    name = "greeter",
    srcs = ["greeter.cc"],
    hdrs = ["greeter.h"],
    deps = ["@abseil-cpp//absl/strings"],  # BCR dep; provides absl::StrCat
    visibility = ["//visibility:public"],  # allows //cpp/app to depend on this
)

cc_test(
    name = "greeter_test",
    srcs = ["greeter_test.cc"],
    deps = [
        ":greeter",
        "@googletest//:gtest_main",  # BCR dep; provides TEST(), EXPECT_EQ(), and main()
    ],
)
```

- [ ] **Step 6: Replace `cpp/app/BUILD.bazel` with the commented version**

```python
# BUILD.bazel — C++ greeter executable.
#
# cc_binary links main.cc with two dependencies:
#   //cpp/greeter  — the internal greeter library defined in this workspace.
#   @spdlog        — the spdlog logging library, a non-BCR dep fetched via
#                    the module extension in //third_party:extensions.bzl.
#
# Run with: bazel run //cpp/app:app
# Docs: https://bazel.build/reference/be/c-cpp#cc_binary
load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "app",
    srcs = ["main.cc"],
    deps = [
        "//cpp/greeter",     # internal dep — workspace-rooted label
        "@spdlog//:spdlog",  # non-BCR dep via //third_party:extensions.bzl
    ],
)
```

- [ ] **Step 7: Replace `go/greeter/BUILD.bazel` with the commented version**

```python
# BUILD.bazel — Go greeter library and unit tests.
#
# go_library compiles greeter.go into a library importable by other Go targets.
# The importpath must match the Go module path declared in go.mod plus the
# relative directory path within that module.
#
# go_test compiles the external test package (package greeter_test) and links
# it against the greeter library.  The external package convention (suffix _test)
# prevents import cycles and is idiomatic in Go.
#
# Run tests with: bazel test //go/greeter:greeter_test
# Docs: https://github.com/bazelbuild/rules_go/blob/main/docs/go/core/rules.md
load("@rules_go//go:def.bzl", "go_library", "go_test")

go_library(
    name = "greeter",
    srcs = ["greeter.go"],
    importpath = "github.com/mike-boquard/bazel-intro/go/greeter",
    visibility = ["//visibility:public"],
)

go_test(
    name = "greeter_test",
    srcs = ["greeter_test.go"],
    deps = [":greeter"],
)
```

- [ ] **Step 8: Replace `go/app/BUILD.bazel` with the commented version**

```python
# BUILD.bazel — Go greeter executable.
#
# go_binary compiles main.go into a standalone binary.  It depends on two
# targets:
#   //go/greeter                    — internal library from this workspace.
#   @com_github_fatih_color//:color — github.com/fatih/color, a third-party
#                                     Go package fetched from the Go module
#                                     proxy via go.mod and Gazelle.  The label
#                                     follows Gazelle's naming convention:
#                                     @com_<reversed-host>_<user>_<repo>//:pkg
#
# Run with: bazel run //go/app:app
# Docs: https://github.com/bazelbuild/rules_go/blob/main/docs/go/core/rules.md
load("@rules_go//go:def.bzl", "go_binary")

go_binary(
    name = "app",
    srcs = ["main.go"],
    deps = [
        "//go/greeter",                    # internal library
        "@com_github_fatih_color//:color", # third-party via go.mod + Gazelle
    ],
)
```

- [ ] **Step 9: Verify all tests still pass (comment-only change — nothing should break)**

```bash
bazel test //...
```

Expected:
```
//cpp/greeter:greeter_test    (cached) PASSED in 0.4s
//go/greeter:greeter_test     (cached) PASSED in 0.4s
Executed 0 out of 2 tests: 2 tests pass.
```

- [ ] **Step 10: Commit**

```bash
cd /Users/mboquard/dev/bazel-intro
git add MODULE.bazel third_party/ cpp/ go/
git commit -s -m "docs: add educational block comments to all Bazel files"
```

---

## Task 2: Add hedron_compile_commands (clangd / compile_commands.json)

`hedron_compile_commands` is not in the BCR — it is added via the existing
`non_registry` module extension, making it a natural second example of the
non-BCR dep pattern alongside spdlog.

**Files:**
- Modify: `third_party/extensions.bzl`
- Modify: `MODULE.bazel`
- Modify: `BUILD.bazel` (root)
- Create: `scripts/refresh_compile_commands.sh`

- [ ] **Step 1: Find the latest hedron_compile_commands commit and compute SHA256**

```bash
# Fetch the commit SHA of the latest release tag
LATEST=$(curl -s https://api.github.com/repos/hedronvision/bazel-compile-commands-extractor/releases/latest \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['tag_name'])")
echo "Latest tag: $LATEST"

# Download the tarball and compute its SHA256
curl -L "https://github.com/hedronvision/bazel-compile-commands-extractor/archive/refs/tags/${LATEST}.tar.gz" \
  -o /tmp/hedron.tar.gz
sha256sum /tmp/hedron.tar.gz
```

Note the tag name and 64-character SHA256 — you will use them in Step 2.

- [ ] **Step 2: Add hedron `http_archive` to `third_party/extensions.bzl`**

Inside `_non_registry_deps_impl`, add a second `http_archive` block after the
spdlog block.  Replace `<TAG>` with the tag from Step 1 (e.g. `v20240221`)
and `<SHA256>` with the hash.

Complete file:

```python
# extensions.bzl — Bzlmod module extension for non-BCR C++ dependencies.
#
# A module extension lets a Bazel module fetch repositories that are not
# listed in the Bazel Central Registry.  This extension uses http_archive()
# to download C++ libraries directly from GitHub releases.
#
# To expose a repo defined here, list it in MODULE.bazel:
#   non_registry = use_extension("//third_party:extensions.bzl", "non_registry")
#   use_repo(non_registry, "<name>")
#
# Docs: https://bazel.build/external/extension
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _non_registry_deps_impl(ctx):
    # spdlog: fast C++ logging library, header-only mode.
    # Not in the BCR, so fetched directly from the GitHub release tarball.
    # build_file injects //third_party:spdlog.BUILD so Bazel can compile it.
    # Docs: https://github.com/gabime/spdlog
    http_archive(
        name = "spdlog",
        url = "https://github.com/gabime/spdlog/archive/refs/tags/v1.14.1.tar.gz",
        sha256 = "1586508029a7d0670dfcb2d97575dcdc242d3868a259742b69f100801ab4e16b",
        strip_prefix = "spdlog-1.14.1",
        build_file = Label("//third_party:spdlog.BUILD"),
    )

    # hedron_compile_commands: generates compile_commands.json for clangd.
    # Not in the BCR, so fetched from GitHub.  The repo ships its own BUILD
    # file so no build_file injection is needed.
    # Docs: https://github.com/hedronvision/bazel-compile-commands-extractor
    http_archive(
        name = "hedron_compile_commands",
        url = "https://github.com/hedronvision/bazel-compile-commands-extractor/archive/refs/tags/<TAG>.tar.gz",
        sha256 = "<SHA256>",
        strip_prefix = "bazel-compile-commands-extractor-<TAG>",
    )

non_registry = module_extension(
    implementation = _non_registry_deps_impl,
)
```

- [ ] **Step 3: Update `use_repo` in `MODULE.bazel`**

Change the existing `use_repo` line from:
```starlark
use_repo(non_registry, "spdlog")
```
to:
```starlark
use_repo(non_registry, "spdlog", "hedron_compile_commands")
```

- [ ] **Step 4: Replace root `BUILD.bazel` with commented version + target**

```python
# BUILD.bazel — root package for the bazel-intro workspace.
#
# Making the workspace root a Bazel package (by placing BUILD.bazel here)
# enables top-level label references such as //:go.mod used by the Gazelle
# go_deps extension in MODULE.bazel.
#
# This file also hosts the compile_commands refresh target, which generates
# compile_commands.json so that clangd (the C++ language server) can resolve
# workspace-rooted include paths like "cpp/greeter/greeter.h".
#
# Docs: https://bazel.build/concepts/build-files

load(
    "@hedron_compile_commands//:refresh_compile_commands.bzl",
    "refresh_compile_commands",
)

# Regenerates compile_commands.json for all C++ targets.
# Re-run this whenever you add or modify C++ source files.
#
# Usage:
#   bazel run //:refresh_compile_commands
#   ./scripts/refresh_compile_commands.sh
#
# Docs: https://github.com/hedronvision/bazel-compile-commands-extractor
refresh_compile_commands(
    name = "refresh_compile_commands",
    targets = {
        "//cpp/...": "",
    },
)
```

- [ ] **Step 5: Create `scripts/refresh_compile_commands.sh`**

```bash
mkdir -p /path/to/bazel-intro/scripts
```

File content for `scripts/refresh_compile_commands.sh`:

```bash
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
```

Make it executable:

```bash
chmod +x scripts/refresh_compile_commands.sh
```

- [ ] **Step 6: Run the script to generate compile_commands.json**

```bash
cd /Users/mboquard/dev/bazel-intro
./scripts/refresh_compile_commands.sh
```

If hedron fails to fetch (sha256 mismatch), Bazel prints the correct hash in the error output. Copy it and update `third_party/extensions.bzl`.

If `strip_prefix` is wrong, Bazel prints the actual paths inside the archive. Update `strip_prefix` to match the first path component shown.

Expected: `compile_commands.json` appears in the workspace root.

```bash
ls -lh compile_commands.json
```

Expected: file exists, non-zero size.

- [ ] **Step 7: Verify all Bazel tests still pass**

```bash
bazel test //...
```

Expected:
```
//cpp/greeter:greeter_test    PASSED in 0.4s
//go/greeter:greeter_test     PASSED in 0.4s
Executed 0 out of 2 tests: 2 tests pass.
```

- [ ] **Step 8: Add compile_commands.json to .gitignore and commit**

`compile_commands.json` is a generated file and should not be committed.

```bash
echo "compile_commands.json" >> /Users/mboquard/dev/bazel-intro/.gitignore
```

Then commit all changes:

```bash
cd /Users/mboquard/dev/bazel-intro
git add third_party/extensions.bzl MODULE.bazel BUILD.bazel scripts/ .gitignore
git commit -s -m "feat: add hedron_compile_commands for clangd/compile_commands.json support"
```

---

## Verification

After both tasks complete:

```bash
# Tests pass
bazel test //...

# Binaries work
bazel run //cpp/app:app
bazel run //go/app:app

# compile_commands.json is regeneratable
./scripts/refresh_compile_commands.sh
ls compile_commands.json

# IDE check: open cpp/greeter/greeter_test.cc in your editor.
# The "file not found" errors on greeter.h should be gone.
```
