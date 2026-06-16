# bazel-intro

[![CI](https://github.com/mike-boquard/bazel-intro/actions/workflows/ci.yml/badge.svg)](https://github.com/mike-boquard/bazel-intro/actions/workflows/ci.yml)

A Bazel workspace demonstrating C++ and Go builds with libraries, executables,
BCR dependencies, non-BCR dependencies, and unit tests.

## Prerequisites

Install [bazelisk](https://github.com/bazelbuild/bazelisk), which manages the
Bazel version automatically using `.bazelversion`:

```bash
brew install bazelisk                      # macOS

# Linux (amd64)
sudo curl -fsSL -o /usr/local/bin/bazel \
  https://github.com/bazelbuild/bazelisk/releases/download/v1.29.0/bazelisk-linux-amd64
sudo chmod +x /usr/local/bin/bazel
```

No separate Go installation is needed — Bazel downloads and caches the Go SDK.

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
test/
  integration/          # sh_test: starts C++ server, calls Go client
third_party/
  extensions.bzl        # Module extension for non-BCR C++ deps
  spdlog.BUILD          # Build rules for spdlog (header-only)
scripts/
  refresh_compile_commands.sh   # Regenerate compile_commands.json for clangd
```

## Build

```bash
# Build everything
bazel build //...

# Build a specific target
bazel build //cpp/greeter
bazel build //cpp/app:app
bazel build //go/greeter
bazel build //go/app:app
```

## Run

```bash
# C++ binary
bazel run //cpp/app:app
bazel run //cpp/app:app -- Alice

# Go binary
bazel run //go/app:app
bazel run //go/app:app -- Alice
```

## Test

```bash
# All tests
bazel test //...

# Individual test targets
bazel test //cpp/greeter:greeter_test
bazel test //go/greeter:greeter_test
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
three targets: `greeter_proto` (language-neutral), `greeter_cc_grpc` (C++ stubs),
and `greeter_go_proto` (Go stubs).

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

## clangd / IDE support

Generate `compile_commands.json` so clangd can resolve C++ includes:

```bash
./scripts/refresh_compile_commands.sh
# or: bazel run //:refresh_compile_commands
```

Re-run after adding or modifying C++ source files. The file is generated at
the workspace root, where clangd finds it automatically.

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
