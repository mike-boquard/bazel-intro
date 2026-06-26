# bazel-intro

[![CI](https://github.com/mike-boquard/bazel-intro/actions/workflows/ci.yml/badge.svg)](https://github.com/mike-boquard/bazel-intro/actions/workflows/ci.yml)

A Bazel workspace demonstrating C++, Go, Python, and Rust builds with libraries,
executables, BCR dependencies, non-BCR dependencies, hermetic pip packages,
a pinned LLVM compiler toolchain, and Rust crates via crate_universe.

## Prerequisites

Install [bazelisk](https://github.com/bazelbuild/bazelisk), which manages the
Bazel version automatically using `.bazelversion`:

```bash
brew install bazelisk                      # macOS
```

```bash
# Linux (amd64) — install to ~/.local/bin (no sudo needed)
mkdir -p ~/.local/bin
curl -fsSL -o ~/.local/bin/bazel \
  https://github.com/bazelbuild/bazelisk/releases/download/v1.29.0/bazelisk-linux-amd64
chmod +x ~/.local/bin/bazel

# Make sure ~/.local/bin is on your PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.local/bin:$PATH"

# Verify
bazel version
```

No separate Go, Python, or Rust installation is needed — Bazel downloads and
caches all SDKs and toolchains automatically.

## Dev container (Linux)

To build and test on Linux without touching your host setup, open the repo in
the included dev container (VS Code: **Dev Containers: Reopen in Container**, or
`devcontainer up --workspace-folder .` with the devcontainer CLI).

It is based on the most recent Ubuntu LTS (`ubuntu:26.04`) and installs only
bazelisk plus a host C/C++ compiler — every other toolchain (Go, Rust, Python,
LLVM) is fetched hermetically by Bazel. The Bazel cache lives in a named volume,
so the heavy first build of gRPC/protobuf/abseil is not repeated on rebuilds.

```bash
# Inside the container, everything works exactly as on the host:
bazel test //...
bazel run //cpp/app:app
```

The base image is pinned in [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json);
change `UBUNTU_VERSION` there (e.g. to `24.04`) if you need a different release.

## Project layout

```
MODULE.bazel            # Bzlmod dependency declarations
go.mod                  # Go module + third-party Go packages
requirements.in         # Python package inputs (edit this)
requirements_lock.txt   # Python package lock with SHA-256 hashes
proto/
  greeter.proto         # Shared gRPC service definition
cpp/
  greeter/              # C++ library (uses abseil from BCR)
  app/                  # C++ binary (uses spdlog, a non-BCR dep)
  server/               # C++ gRPC server implementing GreeterService
go/
  greeter/              # Go library
  app/                  # Go binary (uses github.com/fatih/color)
  client/               # Go gRPC client calling GreeterService
python/
  demo/                 # Python binary demonstrating hermetic pip deps (rich)
rust/
  greeter/              # Rust library with inline #[cfg(test)] unit tests
  app/                  # Rust binary (uses colored crate from crates.io)
test/
  integration/          # sh_test: starts C++ server, calls Go client
third_party/
  extensions.bzl        # Module extension for non-BCR C++ deps
  spdlog.BUILD          # Build rules for spdlog (header-only)
scripts/
  refresh_compile_commands.sh   # Regenerate compile_commands.json for clangd
  refresh_rust_project.sh       # Regenerate rust-project.json for rust-analyzer
  format_cpp.sh                 # Format all C++ files using clang-format
```

> **`BUILD` vs `BUILD.bazel`:** Bazel accepts either filename for a package.
> If both exist in the same directory, `BUILD.bazel` takes precedence. This
> repo uses `BUILD.bazel` everywhere for consistency and clearer editor
> highlighting.

## Build

```bash
# Build everything
bazel build //...

# Build a specific target
bazel build //cpp/greeter
bazel build //cpp/app:app
bazel build //go/greeter
bazel build //go/app:app
bazel build //rust/greeter
bazel build //rust/app:app
```

## Run

```bash
# C++ binary
bazel run //cpp/app:app
bazel run //cpp/app:app -- Alice

# Go binary
bazel run //go/app:app
bazel run //go/app:app -- Alice

# Rust binary
bazel run //rust/app:app
bazel run //rust/app:app -- Alice

# Python demo
bazel run //python/demo:demo
```

## Test

```bash
# All tests
bazel test //...

# Individual test targets
bazel test //cpp/greeter:greeter_test
bazel test //go/greeter:greeter_test
bazel test //rust/greeter:greeter_test
bazel test //test/integration:greeter_integration_test
```

## Proto / gRPC

A shared `.proto` file in `proto/` generates gRPC stubs for both C++ and Go,
demonstrating cross-language communication with a single contract.

```bash
# Run the C++ server (listens on :50051)
bazel run //cpp/server:server

# In another terminal: call it from the Go client
bazel run //go/client:client
bazel run //go/client:client -- localhost:50051 Alice

# Run the integration test (starts server + client automatically)
bazel test //test/integration:greeter_integration_test
```

The proto definition lives in `proto/greeter.proto` and its `BUILD.bazel` produces
four targets: `greeter_proto` (language-neutral), `greeter_cc_proto` (C++ message
classes), `greeter_cc_grpc` (C++ service stubs), and `greeter_go_proto` (Go stubs).

## C++ compiler toolchain

By default, Bazel uses whatever C++ compiler is available on the host (Xcode Clang
on macOS, GCC or system Clang on Linux). This repo also configures a pinned LLVM
toolchain via `toolchains_llvm`:

```bash
# Use the pinned LLVM 18.1.8 toolchain (Linux x86_64 only)
bazel build --config=clang //cpp/...

# macOS: omit --config=clang — the system Xcode Clang is used instead
bazel build //cpp/...
```

The toolchain is declared in MODULE.bazel (`bazel_dep(name = "toolchains_llvm", ...)`).
On Linux the `--config=clang` flag tells Bazel to prefer `@llvm_toolchain//:cc-toolchain-x86_64-linux`.
On macOS, pre-built LLVM arm64 binaries in `toolchains_llvm` 1.7.0 top out at version
17 and have compatibility issues on Apple Silicon, so the system compiler is used.

## Python (hermetic demo)

Demonstrates `rules_python` with locked pip dependencies:

```bash
bazel run //python/demo:demo
```

No `pip install` required. Bazel downloads Python 3.12 and all packages
(declared in `requirements_lock.txt` with SHA-256 hashes) automatically.
The system Python is never used.

To add a new package:

```bash
# 1. Add to requirements.in
echo "httpx==0.27.0" >> requirements.in

# 2. Regenerate the lock file with hashes
pip-compile requirements.in --generate-hashes --output-file requirements_lock.txt

# 3. Sync Bazel's view
bazel mod tidy
```

## Rust

Demonstrates `rules_rust` with a crates.io dependency via `crate_universe`:

```bash
bazel run //rust/app:app
bazel run //rust/app:app -- Alice

# Tests use Rust's idiomatic inline #[cfg(test)] modules
bazel test //rust/greeter:greeter_test
```

No system Rust installation is needed — Bazel downloads Rust 1.85.0 automatically.
The `colored` crate is declared in MODULE.bazel via `crate.spec()` and fetched
from crates.io by `crate_universe`.

To add a new crate:

```bash
# 1. Add a crate.spec() call in MODULE.bazel
# 2. Sync Bazel's view
bazel mod tidy
```

### Using a `Cargo.toml` instead

This repo declares crates inline with `crate.spec()` + `crate.from_specs()`,
keeping all dependency info in `MODULE.bazel` with no Cargo files. If you'd
rather drive `crate_universe` from a real Cargo manifest (e.g. an existing
Cargo project), swap `from_specs()` for `from_cargo()`:

```starlark
crate = use_extension("@rules_rust//crate_universe:extensions.bzl", "crate")
crate.from_cargo(
    cargo_lockfile = "//:Cargo.lock",
    manifests = ["//:Cargo.toml"],
)
use_repo(crate, "crates")
```

`crate_universe` then reads your `Cargo.toml` / `Cargo.lock` directly. Both
approaches produce the same `@crates//:<name>` labels used in BUILD files.

## IDE support

### C++ — clangd

Generate `compile_commands.json` so clangd can resolve C++ includes:

```bash
./scripts/refresh_compile_commands.sh
# or: bazel run //:refresh_compile_commands
```

Re-run after adding or modifying C++ source files. The file is generated at
the workspace root, where clangd finds it automatically.

### Rust — rust-analyzer

Generate `rust-project.json` so rust-analyzer can resolve crate imports
without a `Cargo.toml`:

```bash
./scripts/refresh_rust_project.sh
# or: bazel run //:gen_rust_project
```

Re-run after adding new `rust_library` or `rust_binary` targets. The file is
generated at the workspace root. If your editor doesn't pick it up
automatically, add this to `.vscode/settings.json` (already present in this
repo):

```json
{
  "rust-analyzer.linkedProjects": ["rust-project.json"]
}
```

## Bazel file formatting (buildifier)

`BUILD.bazel`, `.bzl`, and `MODULE.bazel` files are formatted and linted with
[buildifier](https://github.com/keith/buildifier-prebuilt), fetched from the
BCR — no system install required.

```bash
# Format all Bazel files in-place
bazel run //:buildifier

# Check mode — exit 1 if any file would change (useful in CI)
bazel run //:buildifier.check
```

Buildifier also warns about deprecated patterns (e.g., functions that must be
explicitly loaded in Bazel 8+). The repo is kept warning-free so `buildifier.check`
can be added to CI as a quality gate.

## C++ formatting (clang-format)

C++ source files are formatted with clang-format 18.1.8, fetched from the
BCR-downloaded LLVM toolchain — no system clang-format required. Style is
defined in `.clang-format` at the workspace root (LLVM style, 4-space indent,
100-column limit).

```bash
# Format all C++ files in-place
./scripts/format_cpp.sh

# Check mode — exit 1 if any file would change (useful in CI)
./scripts/format_cpp.sh --check
```

Both forms invoke `bazel run //:clang-format` under the hood, which ensures
the exact same binary is used everywhere regardless of what is installed on
the host.

## Adding a new Go dependency

```bash
# 1. Fetch the package
bazel run @rules_go//go -- get github.com/some/package@v1.2.3

# 2. Update MODULE.bazel use_repo entries
bazel mod tidy

# 3. Regenerate BUILD files
bazel run @gazelle//:gazelle -- go/
```

## Dependency overview

| Dependency | Source | Used for |
|---|---|---|
| `abseil-cpp` | BCR | `absl::StrCat` in C++ greeter library |
| `googletest` | BCR | C++ unit tests |
| `toolchains_llvm` | BCR | Pinned LLVM/Clang toolchain (Linux, opt-in via `--config=clang`) |
| `rules_go` | BCR | Go build rules and toolchain |
| `gazelle` | BCR | Go BUILD file generation and go.mod integration |
| `rules_python` | BCR | Hermetic Python toolchain and `py_binary` rules |
| `spdlog` | non-BCR (http_archive) | Logging in C++ binary |
| `hedron_compile_commands` | non-BCR (http_archive) | `compile_commands.json` for clangd |
| `github.com/fatih/color` | Go module proxy | Colorized output in Go binary |
| `protobuf` | BCR | Proto codegen and `proto_library` rule |
| `grpc` | BCR | C++ gRPC runtime and `cc_grpc_library` codegen |
| `google.golang.org/grpc` | Go module proxy | Go gRPC runtime |
| `rich` | PyPI (requirements_lock.txt) | Terminal formatting in Python demo |
| `rules_rust` | BCR | Rust build rules and hermetic rustc toolchain |
| `colored` | crates.io (crate_universe) | Colorized output in Rust binary |
| `buildifier_prebuilt` | BCR (dev) | Bazel file formatter/linter (`//:buildifier`) |
| `rules_shell` | BCR | `sh_test` rule (explicit load required in Bazel 8+) |
