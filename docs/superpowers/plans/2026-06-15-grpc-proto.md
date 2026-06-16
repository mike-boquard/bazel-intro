# gRPC + Shared Proto Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a shared `greeter.proto` that generates C++ and Go gRPC stubs, a C++ server, a Go client, and a `bazel test` integration test that starts the server and calls it from the client.

**Architecture:** One `.proto` file in `proto/` produces three generated targets (proto_library, cc_grpc_library, go_proto_library). The C++ server binary implements GreeterService. The Go client binary calls it. A `sh_test` wires both binaries together: it starts the server in the background, polls until port 50051 opens, runs the client, and asserts the response. All C++ dependencies come from the BCR; Go gRPC comes through `go.mod`.

**Tech Stack:** Bazel 7.4.1, Bzlmod, `protobuf` (BCR), `grpc` (BCR), `rules_go` go_proto_library + go_grpc compiler, `google.golang.org/grpc` (Go module proxy), sh_test.

---

## File Map

| File | Change |
|------|--------|
| `MODULE.bazel` | Add `protobuf` + `grpc` BCR deps; expand `go_deps` use_repo after mod tidy |
| `go.mod` / `go.sum` | Add `google.golang.org/grpc` + `google.golang.org/protobuf` |
| `proto/greeter.proto` | Create — proto contract |
| `proto/BUILD.bazel` | Create — proto_library, cc_proto_library, cc_grpc_library, go_proto_library |
| `cpp/server/main.cc` | Create — C++ gRPC server |
| `cpp/server/BUILD.bazel` | Create — cc_binary |
| `go/client/main.go` | Create — Go gRPC client |
| `go/client/BUILD.bazel` | Create — go_binary (Gazelle-generated then adjusted) |
| `test/integration/greeter_test.sh` | Create — integration test script |
| `test/integration/BUILD.bazel` | Create — sh_test |
| `README.md` | Add Proto/gRPC section + update dependency table |

---

## Task 1: Add protobuf and grpc BCR deps to MODULE.bazel

**Files:**
- Modify: `MODULE.bazel`

- [ ] **Step 1: Check available BCR versions**

```bash
cd /Users/mboquard/dev/bazel-intro
bazel mod deps --lockfile_mode=off 2>/dev/null | head -5  # just to ensure bazel runs
```

The versions to add are `protobuf 29.3` and `grpc 1.68.1`. If either fails to resolve in Step 3, check available versions at https://registry.bazel.build/modules/protobuf and https://registry.bazel.build/modules/grpc and substitute the latest available version.

- [ ] **Step 2: Add the two new BCR deps to `MODULE.bazel`**

Insert after the existing `# ── C++ testing and libraries` stanza (after line 29, `abseil-cpp`):

```starlark
# ── Proto and gRPC (BCR) ──────────────────────────────────────────────────────
# protobuf — proto_library rule, protoc compiler, and cc_proto_library support.
#             Provides the language-neutral proto_library and cc_proto_library
#             rules used in proto/BUILD.bazel.
#             BCR: https://registry.bazel.build/modules/protobuf
# grpc      — C++ gRPC runtime and the cc_grpc_library codegen macro.
#             The Go gRPC runtime comes from go.mod (google.golang.org/grpc),
#             not from this module.
#             BCR: https://registry.bazel.build/modules/grpc
bazel_dep(name = "protobuf", version = "29.3")
bazel_dep(name = "grpc", version = "1.68.1")
```

- [ ] **Step 3: Verify the module graph resolves**

```bash
cd /Users/mboquard/dev/bazel-intro
bazel mod graph 2>&1 | grep -E "protobuf|grpc" | head -10
```

Expected: lines mentioning `protobuf@29.3` and `grpc@1.68.1` in the graph. If a version is unavailable, the error will say `no such module`. In that case, check https://registry.bazel.build for the latest available version and update MODULE.bazel.

- [ ] **Step 4: Ensure existing build still passes**

```bash
bazel build //... 2>&1 | tail -5
```

Expected: `Build completed successfully` (or `INFO: Build completed successfully, X total actions`).

- [ ] **Step 5: Commit**

```bash
cd /Users/mboquard/dev/bazel-intro
git add MODULE.bazel
git commit -s -m "deps: add protobuf and grpc BCR modules"
```

---

## Task 2: Add Go gRPC deps to go.mod

**Files:**
- Modify: `go.mod`, `go.sum`
- Modify: `MODULE.bazel` (use_repo line updated by bazel mod tidy)

- [ ] **Step 1: Add google.golang.org/grpc to go.mod**

```bash
cd /Users/mboquard/dev/bazel-intro
bazel run @rules_go//go -- get google.golang.org/grpc@v1.68.1
```

Expected: `go.mod` now contains `require google.golang.org/grpc v1.68.1`.

- [ ] **Step 2: Add google.golang.org/protobuf to go.mod**

```bash
bazel run @rules_go//go -- get google.golang.org/protobuf@v1.36.0
```

Expected: `go.mod` now contains `require google.golang.org/protobuf v1.36.0`.

- [ ] **Step 3: Tidy go.mod to pull in transitive deps**

```bash
bazel run @rules_go//go -- mod tidy
```

Expected: `go.sum` updated; `go.mod` may gain indirect deps like `golang.org/x/net`, `google.golang.org/genproto`.

- [ ] **Step 4: Update MODULE.bazel use_repo with new Go deps**

```bash
bazel mod tidy
```

Expected: The `use_repo(go_deps, ...)` line in `MODULE.bazel` is updated to include the grpc/protobuf Go repos (names like `org_golang_google_grpc`, `org_golang_google_protobuf`, etc.). Accept whatever `bazel mod tidy` produces — do not hand-edit `use_repo`.

- [ ] **Step 5: Verify existing tests still pass**

```bash
bazel test //...
```

Expected: both greeter tests pass, no new failures.

- [ ] **Step 6: Commit**

```bash
cd /Users/mboquard/dev/bazel-intro
git add go.mod go.sum MODULE.bazel
git commit -s -m "deps: add google.golang.org/grpc and protobuf to go.mod"
```

---

## Task 3: Proto definition and BUILD.bazel

**Files:**
- Create: `proto/greeter.proto`
- Create: `proto/BUILD.bazel`

- [ ] **Step 1: Create `proto/greeter.proto`**

```proto
syntax = "proto3";

package greeter;

// go_package sets the Go import path for the generated Go code.
// Must match the importpath in go_proto_library below.
option go_package = "github.com/mike-boquard/bazel-intro/proto/greeter";

// GreeterService exposes a single SayHello RPC.
service GreeterService {
  rpc SayHello (HelloRequest) returns (HelloReply);
}

message HelloRequest {
  string name = 1;
}

message HelloReply {
  string message = 1;
}
```

- [ ] **Step 2: Create `proto/BUILD.bazel`**

```python
# BUILD.bazel — Proto targets for the shared GreeterService contract.
#
# Build chain:
#   greeter_proto (proto_library)
#     └─ greeter_cc_proto  (cc_proto_library)  ← C++ message classes
#         └─ greeter_cc_grpc (cc_grpc_library) ← C++ service stubs
#     └─ greeter_go_proto  (go_proto_library)  ← Go message + service stubs
#
# proto_library is a native Bazel rule (no load needed).
# Docs: https://bazel.build/reference/be/protocol-buffer#proto_library
#
# cc_grpc_library docs: https://grpc.io/docs/languages/cpp/bazel/
# go_proto_library docs: https://github.com/bazelbuild/rules_go/blob/main/docs/proto/core.md

load("@grpc//:cc_grpc_library.bzl", "cc_grpc_library")
load("@rules_go//proto:def.bzl", "go_proto_library")

# language-neutral proto target; consumed by all language-specific rules below
proto_library(
    name = "greeter_proto",
    srcs = ["greeter.proto"],
    visibility = ["//visibility:public"],
)

# Generates greeter.pb.h / greeter.pb.cc (C++ message classes).
# cc_proto_library is a native Bazel rule provided by the protobuf BCR module.
cc_proto_library(
    name = "greeter_cc_proto",
    deps = [":greeter_proto"],
    visibility = ["//visibility:public"],
)

# Generates greeter.grpc.pb.h / greeter.grpc.pb.cc (C++ service stubs).
# grpc_only = True: only generates service stubs; messages come from greeter_cc_proto.
cc_grpc_library(
    name = "greeter_cc_grpc",
    srcs = [":greeter_proto"],
    grpc_only = True,
    deps = [":greeter_cc_proto"],
    visibility = ["//visibility:public"],
)

# Generates Go protobuf + gRPC code in one step.
# compilers = ["@rules_go//proto:go_grpc"] emits both message types and service stubs.
# importpath must match the go_package option in greeter.proto.
go_proto_library(
    name = "greeter_go_proto",
    compilers = ["@rules_go//proto:go_grpc"],
    importpath = "github.com/mike-boquard/bazel-intro/proto/greeter",
    proto = ":greeter_proto",
    visibility = ["//visibility:public"],
)
```

**Troubleshooting note:** If the `load("@grpc//:cc_grpc_library.bzl", ...)` fails with "file not found", try `load("@grpc//bazel:cc_grpc_library.bzl", "cc_grpc_library")` instead — the load path varies between grpc versions.

- [ ] **Step 3: Build the proto_library**

```bash
cd /Users/mboquard/dev/bazel-intro
bazel build //proto:greeter_proto
```

Expected: `Build completed successfully`.

- [ ] **Step 4: Build the C++ gRPC stubs**

```bash
bazel build //proto:greeter_cc_grpc
```

Expected: `Build completed successfully`. This confirms protoc + grpc plugin ran and generated `.grpc.pb.h`.

- [ ] **Step 5: Build the Go proto stubs**

```bash
bazel build //proto:greeter_go_proto
```

Expected: `Build completed successfully`. This confirms the go_grpc compiler ran.

- [ ] **Step 6: Commit**

```bash
cd /Users/mboquard/dev/bazel-intro
git add proto/
git commit -s -m "feat: add greeter.proto with C++ and Go gRPC stubs"
```

---

## Task 4: C++ gRPC Server

**Files:**
- Create: `cpp/server/main.cc`
- Create: `cpp/server/BUILD.bazel`

- [ ] **Step 1: Create `cpp/server/main.cc`**

```cpp
#include <iostream>
#include <memory>
#include <string>

#include <grpcpp/grpcpp.h>
#include "proto/greeter.grpc.pb.h"

// GreeterServiceImpl handles incoming SayHello RPCs.
class GreeterServiceImpl final : public greeter::GreeterService::Service {
  grpc::Status SayHello(grpc::ServerContext* context,
                        const greeter::HelloRequest* request,
                        greeter::HelloReply* reply) override {
    reply->set_message("Hello, " + request->name() + "!");
    return grpc::Status::OK;
  }
};

int main() {
  std::string addr = "0.0.0.0:50051";
  GreeterServiceImpl service;

  grpc::ServerBuilder builder;
  builder.AddListeningPort(addr, grpc::InsecureServerCredentials());
  builder.RegisterService(&service);

  auto server = builder.BuildAndStart();
  // Print to stdout so the integration test can detect startup.
  std::cout << "Listening on " << addr << std::endl;
  server->Wait();
  return 0;
}
```

- [ ] **Step 2: Create `cpp/server/BUILD.bazel`**

```python
# BUILD.bazel — C++ gRPC server binary.
#
# Depends on the generated C++ stubs from //proto and the gRPC C++ runtime
# from the BCR grpc module.
#
# @grpc//:grpc++ is the main C++ gRPC runtime library (ServerBuilder, etc.).
# Docs: https://grpc.io/docs/languages/cpp/bazel/
load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "server",
    srcs = ["main.cc"],
    deps = [
        "//proto:greeter_cc_grpc",
        "//proto:greeter_cc_proto",
        "@grpc//:grpc++",
    ],
)
```

- [ ] **Step 3: Build the server**

```bash
cd /Users/mboquard/dev/bazel-intro
bazel build //cpp/server:server
```

Expected: `Build completed successfully`. The first build downloads grpc and compiles it — this may take several minutes.

- [ ] **Step 4: Smoke-test the server starts**

```bash
bazel run //cpp/server:server &
SERVER_PID=$!
sleep 1
kill $SERVER_PID 2>/dev/null || true
```

Expected: `Listening on 0.0.0.0:50051` printed before the kill.

- [ ] **Step 5: Commit**

```bash
cd /Users/mboquard/dev/bazel-intro
git add cpp/server/
git commit -s -m "feat: add C++ gRPC server implementing GreeterService"
```

---

## Task 5: Go gRPC Client

**Files:**
- Create: `go/client/main.go`
- Create: `go/client/BUILD.bazel`

- [ ] **Step 1: Create `go/client/main.go`**

```go
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pb "github.com/mike-boquard/bazel-intro/proto/greeter"
)

func main() {
	addr := "localhost:50051"
	if len(os.Args) > 1 {
		addr = os.Args[1]
	}
	name := "World"
	if len(os.Args) > 2 {
		name = os.Args[2]
	}

	conn, err := grpc.NewClient(addr,
		grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("failed to connect to %s: %v", addr, err)
	}
	defer conn.Close()

	client := pb.NewGreeterServiceClient(conn)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	resp, err := client.SayHello(ctx, &pb.HelloRequest{Name: name})
	if err != nil {
		log.Fatalf("SayHello failed: %v", err)
	}
	fmt.Println(resp.GetMessage())
}
```

- [ ] **Step 2: Generate `go/client/BUILD.bazel` with Gazelle**

```bash
cd /Users/mboquard/dev/bazel-intro
bazel run @gazelle//:gazelle -- go/client/
```

Gazelle reads the imports in `main.go` and generates `go/client/BUILD.bazel`. Inspect the generated file — it should contain a `go_binary` with deps for `//proto:greeter_go_proto`, `@org_golang_google_grpc//:grpc` (or similar), and `@org_golang_google_grpc//credentials/insecure`.

If Gazelle does not generate a BUILD.bazel (e.g. due to unresolved imports), create it manually:

```python
# BUILD.bazel — Go gRPC client binary.
#
# Connects to the C++ gRPC server and calls SayHello.
# //proto:greeter_go_proto provides the generated Go stubs.
# @org_golang_google_grpc is the Go gRPC runtime (from go.mod, not BCR).
# Docs: https://github.com/bazelbuild/rules_go/blob/main/docs/go/core/rules.md
load("@rules_go//go:def.bzl", "go_binary")

go_binary(
    name = "client",
    srcs = ["main.go"],
    deps = [
        "//proto:greeter_go_proto",
        "@org_golang_google_grpc//:grpc",
        "@org_golang_google_grpc//credentials/insecure",
    ],
)
```

**Note on dep labels:** The exact Bazel label for `google.golang.org/grpc` is determined by Gazelle's go_deps extension. It is almost certainly `@org_golang_google_grpc//:grpc`. If the build fails with "no such target", run `bazel query @org_golang_google_grpc//...` to list available targets and adjust.

- [ ] **Step 3: Build the client**

```bash
cd /Users/mboquard/dev/bazel-intro
bazel build //go/client:client
```

Expected: `Build completed successfully`.

- [ ] **Step 4: Smoke-test client + server together**

In terminal 1:
```bash
bazel run //cpp/server:server
```

In terminal 2:
```bash
bazel run //go/client:client
```

Expected terminal 2 output: `Hello, World!`

```bash
bazel run //go/client:client -- localhost:50051 Alice
```

Expected: `Hello, Alice!`

- [ ] **Step 5: Commit**

```bash
cd /Users/mboquard/dev/bazel-intro
git add go/client/
git commit -s -m "feat: add Go gRPC client calling GreeterService"
```

---

## Task 6: Integration Test

**Files:**
- Create: `test/integration/greeter_test.sh`
- Create: `test/integration/BUILD.bazel`

- [ ] **Step 1: Create `test/integration/` directory**

```bash
mkdir -p /Users/mboquard/dev/bazel-intro/test/integration
```

- [ ] **Step 2: Create `test/integration/greeter_test.sh`**

```bash
#!/usr/bin/env bash
# Integration test: starts the C++ gRPC server, calls it with the Go client,
# and asserts the response is "Hello, World!".
#
# Bazel places test data under $TEST_SRCDIR/<workspace_name>/.
# The workspace name is "bazel_intro" (from MODULE.bazel module(...)).
set -euo pipefail

WS="${TEST_SRCDIR}/bazel_intro"
SERVER_BIN="${WS}/cpp/server/server"
CLIENT_BIN="${WS}/go/client/client"

# Start the C++ server in the background; kill it when the test exits.
"$SERVER_BIN" &
SERVER_PID=$!
trap "kill $SERVER_PID 2>/dev/null || true" EXIT

# Poll until port 50051 accepts connections (up to 5 seconds).
for i in $(seq 1 20); do
  if nc -z localhost 50051 2>/dev/null; then
    break
  fi
  if [[ $i -eq 20 ]]; then
    echo "FAIL: server did not start within 5 seconds"
    exit 1
  fi
  sleep 0.25
done

# Call the server and capture the response.
OUTPUT=$("$CLIENT_BIN" localhost:50051 World)

if [[ "$OUTPUT" == "Hello, World!" ]]; then
  echo "PASS: got '$OUTPUT'"
  exit 0
else
  echo "FAIL: expected 'Hello, World!', got '$OUTPUT'"
  exit 1
fi
```

**Note on binary paths:** `$TEST_SRCDIR/bazel_intro/` maps to the workspace root in the runfiles tree. `go_binary` targets land at `<package>/<name>` (no wrapper subdirectory). If the test fails with "no such file", verify the path with:
```bash
bazel build //cpp/server:server //go/client:client
ls bazel-bin/cpp/server/server bazel-bin/go/client/client
```

Make the script executable:
```bash
chmod +x /Users/mboquard/dev/bazel-intro/test/integration/greeter_test.sh
```

- [ ] **Step 3: Create `test/integration/BUILD.bazel`**

```python
# BUILD.bazel — Cross-language integration test.
#
# sh_test starts the C++ gRPC server, calls it with the Go client, and asserts
# the response. Both binaries are listed in data so Bazel builds them before
# running the test.
#
# $TEST_SRCDIR is set by Bazel to the runfiles directory at test time.
# Binaries are located at $TEST_SRCDIR/<workspace_name>/<package>/<binary>.
#
# Docs: https://bazel.build/reference/be/shell#sh_test

sh_test(
    name = "greeter_integration_test",
    srcs = ["greeter_test.sh"],
    data = [
        "//cpp/server:server",
        "//go/client:client",
    ],
)
```

- [ ] **Step 4: Run the integration test**

```bash
cd /Users/mboquard/dev/bazel-intro
bazel test //test/integration:greeter_integration_test --test_output=all
```

Expected:
```
//test/integration:greeter_integration_test    PASSED in X.Xs
PASS: got 'Hello, World!'
```

If it fails with a path error, read the test log:
```bash
cat $(bazel info bazel-testlogs)/test/integration/greeter_integration_test/test.log
```

Use the log output to identify the correct Go binary path (the `_/client` wrapper) and update `CLIENT_BIN` in `greeter_test.sh`.

- [ ] **Step 5: Run full test suite to confirm nothing regressed**

```bash
bazel test //...
```

Expected: all 3 tests pass (`cpp/greeter:greeter_test`, `go/greeter:greeter_test`, `test/integration:greeter_integration_test`).

- [ ] **Step 6: Commit**

```bash
cd /Users/mboquard/dev/bazel-intro
git add test/
git commit -s -m "test: add gRPC cross-language integration test"
```

---

## Task 7: README update

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add a Proto / gRPC section to README.md**

Insert the following section after the existing `## Test` section (before `## clangd / IDE support`):

```markdown
## Proto / gRPC

A shared `.proto` file in `proto/` generates gRPC stubs for both C++ and Go,
demonstrating cross-language communication from a single contract.

```bash
# Run the C++ gRPC server (listens on :50051)
bazel run //cpp/server:server

# In a second terminal — call it from the Go client
bazel run //go/client:client
bazel run //go/client:client -- localhost:50051 Alice

# Run the integration test (starts server + client automatically)
bazel test //test/integration:greeter_integration_test
```
```

- [ ] **Step 2: Update the dependency table**

Add three rows to the existing dependency table in `README.md`:

```markdown
| `protobuf` | BCR | Proto codegen + `proto_library` rule |
| `grpc` | BCR | C++ gRPC runtime + `cc_grpc_library` codegen |
| `google.golang.org/grpc` | Go module proxy | Go gRPC runtime |
```

- [ ] **Step 3: Verify README renders correctly**

```bash
# Quick sanity check that the file is valid markdown (no unclosed fences)
python3 -c "
import re, sys
content = open('README.md').read()
fences = re.findall(r'^\`\`\`', content, re.MULTILINE)
if len(fences) % 2 != 0:
    print('ERROR: odd number of code fences')
    sys.exit(1)
print('README.md OK:', len(fences) // 2, 'code blocks')
"
```

Expected: `README.md OK: N code blocks` (no error).

- [ ] **Step 4: Commit**

```bash
cd /Users/mboquard/dev/bazel-intro
git add README.md
git commit -s -m "docs: add Proto/gRPC section to README"
```

---

## Verification

After all tasks are committed:

```bash
# All targets build
bazel build //...

# All 3 tests pass
bazel test //...

# Integration test passes with verbose output
bazel test //test/integration:greeter_integration_test --test_output=all

# Manual cross-language demo
bazel run //cpp/server:server &
sleep 1
bazel run //go/client:client -- localhost:50051 World
bazel run //go/client:client -- localhost:50051 Alice
kill %1
```

Expected final test output:
```
//cpp/greeter:greeter_test                               PASSED
//go/greeter:greeter_test                                PASSED
//test/integration:greeter_integration_test              PASSED
```
