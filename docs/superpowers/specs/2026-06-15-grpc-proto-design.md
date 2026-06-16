# gRPC + Shared Proto Design

**Date:** 2026-06-15
**Status:** Approved

## Goal

Add a shared `.proto` file that generates gRPC stubs for both C++ and Go, with a
C++ gRPC server, a Go gRPC client, and a `bazel test`-compatible integration test
that starts the server, calls it from the client, and asserts the response.

## Architecture

One `.proto` file in `proto/` defines the `GreeterService` contract. Its
`BUILD.bazel` produces three generated targets: a `proto_library` (language-
neutral), a `cc_grpc_library` (C++ stubs), and a `go_proto_library` (Go stubs).
The C++ server and Go client are thin binaries that depend on those generated
targets. The integration test is a `sh_test` that wires the two binaries together
at test time.

## Proto Contract

File: `proto/greeter.proto`

```proto
syntax = "proto3";
package greeter;
option go_package = "github.com/mike-boquard/bazel-intro/proto/greeter";

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

## File Map

| File | Change |
|------|--------|
| `proto/greeter.proto` | Create — proto contract |
| `proto/BUILD.bazel` | Create — proto_library, cc_grpc_library, go_proto_library |
| `cpp/server/main.cc` | Create — C++ gRPC server |
| `cpp/server/BUILD.bazel` | Create — cc_binary |
| `go/client/main.go` | Create — Go gRPC client |
| `go/client/BUILD.bazel` | Create — go_binary |
| `test/integration/greeter_test.sh` | Create — integration test script |
| `test/integration/BUILD.bazel` | Create — sh_test target |
| `MODULE.bazel` | Modify — add protobuf + grpc BCR deps; expand go_deps use_repo |
| `go.mod` / `go.sum` | Modify — add google.golang.org/grpc + google.golang.org/protobuf |
| `README.md` | Modify — add Proto/gRPC section |

---

## Dependencies

### MODULE.bazel additions

```starlark
# protobuf — proto_library rule + protoc compiler + cc_proto_library support.
# BCR: https://registry.bazel.build/modules/protobuf
bazel_dep(name = "protobuf", version = "29.3")

# grpc — C++ gRPC runtime and cc_grpc_library codegen macro.
# BCR: https://registry.bazel.build/modules/grpc
bazel_dep(name = "grpc", version = "1.68.1")
```

`protobuf` and `grpc` are added after the existing `rules_cc` stanza.
The `go_deps` `use_repo()` line must be expanded after running `bazel mod tidy`
to include `org_golang_google_grpc`, `org_golang_google_protobuf`, and any
transitive deps Gazelle resolves.

### go.mod additions

```
require google.golang.org/grpc v1.68.1
require google.golang.org/protobuf v1.36.0
```

Transitive deps (e.g. `golang.org/x/net`, `google.golang.org/genproto`) will be
added by `bazel run @rules_go//go -- mod tidy`.

---

## `proto/BUILD.bazel`

```python
# proto_library declares the .proto source as a Bazel target.
# Docs: https://bazel.build/reference/be/protocol-buffer#proto_library
proto_library(
    name = "greeter_proto",
    srcs = ["greeter.proto"],
    visibility = ["//visibility:public"],
)

# cc_proto_library generates C++ message classes from the proto.
# Required as a dep by cc_grpc_library.
cc_proto_library(
    name = "greeter_cc_proto",
    deps = [":greeter_proto"],
    visibility = ["//visibility:public"],
)

# cc_grpc_library generates C++ gRPC service stubs (greeter.grpc.pb.h/.cc).
# grpc_only = True means it only generates the service stubs; message code
# comes from greeter_cc_proto above.
# Docs: https://grpc.io/docs/languages/cpp/bazel/
load("@grpc//:cc_grpc_library.bzl", "cc_grpc_library")
cc_grpc_library(
    name = "greeter_cc_grpc",
    srcs = [":greeter_proto"],
    grpc_only = True,
    deps = [":greeter_cc_proto"],
    visibility = ["//visibility:public"],
)

# go_proto_library generates Go protobuf + gRPC code from the proto.
# The go_grpc compiler emits both the message types and the service stubs.
# importpath must match the go_package option in greeter.proto.
# Docs: https://github.com/bazelbuild/rules_go/blob/main/docs/proto/core.md
load("@rules_go//proto:def.bzl", "go_proto_library")
go_proto_library(
    name = "greeter_go_proto",
    compilers = ["@rules_go//proto:go_grpc"],
    importpath = "github.com/mike-boquard/bazel-intro/proto/greeter",
    proto = ":greeter_proto",
    visibility = ["//visibility:public"],
)
```

---

## C++ Server

File: `cpp/server/main.cc`

```cpp
#include <iostream>
#include <memory>
#include <string>

#include <grpcpp/grpcpp.h>
#include "proto/greeter.grpc.pb.h"

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
  std::cout << "Listening on " << addr << std::endl;
  server->Wait();
  return 0;
}
```

File: `cpp/server/BUILD.bazel`

```python
# cc_binary for the gRPC server.
# Deps:
#   //proto:greeter_cc_grpc  — generated service stubs (greeter.grpc.pb.h)
#   //proto:greeter_cc_proto — generated message classes (greeter.pb.h)
#   @grpc//:grpc++           — C++ gRPC runtime
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

---

## Go Client

File: `go/client/main.go`

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
		log.Fatalf("failed to connect: %v", err)
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

File: `go/client/BUILD.bazel`

```python
# go_binary for the gRPC client.
# Deps:
#   //proto:greeter_go_proto          — generated Go proto+gRPC stubs
#   @org_golang_google_grpc//:grpc    — Go gRPC runtime (from go.mod)
#   @org_golang_google_grpc//credentials/insecure — insecure transport
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

---

## Integration Test

File: `test/integration/greeter_test.sh`

```bash
#!/usr/bin/env bash
# Integration test: starts the C++ gRPC server, calls it from the Go client,
# asserts the response is "Hello, World!".
set -euo pipefail

SERVER_BIN=$1
CLIENT_BIN=$2

# Start server in background; kill it on exit.
"$SERVER_BIN" &
SERVER_PID=$!
trap "kill $SERVER_PID 2>/dev/null || true" EXIT

# Poll until port 50051 is open (up to 5 seconds).
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

# Call the server and capture output.
OUTPUT=$("$CLIENT_BIN" localhost:50051 World)

if [[ "$OUTPUT" == "Hello, World!" ]]; then
  echo "PASS: got '$OUTPUT'"
  exit 0
else
  echo "FAIL: expected 'Hello, World!', got '$OUTPUT'"
  exit 1
fi
```

File: `test/integration/BUILD.bazel`

```python
# sh_test wires the C++ server and Go client together for a cross-language
# integration test. Both binaries are listed in data so Bazel builds them
# before running the test. $(rootpath ...) resolves to the runfile path at
# test execution time.
# Docs: https://bazel.build/reference/be/shell#sh_test

sh_test(
    name = "greeter_integration_test",
    srcs = ["greeter_test.sh"],
    args = [
        "$(rootpath //cpp/server:server)",
        "$(rootpath //go/client:client)",
    ],
    data = [
        "//cpp/server:server",
        "//go/client:client",
    ],
)
```

---

## README additions

Add a **Proto / gRPC** section after the existing Test section:

```markdown
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
```

Also update the **Dependency overview** table with:

| `protobuf` | BCR | Proto codegen + `proto_library` rule |
| `grpc` | BCR | C++ gRPC runtime and `cc_grpc_library` codegen |
| `google.golang.org/grpc` | Go module proxy | Go gRPC runtime |

---

## What is NOT in scope

- TLS / authenticated channels (insecure credentials only)
- Server reflection or health-check protocol
- Streaming RPCs
- A Go server or C++ client (one server + one client is sufficient to demonstrate the pattern)
- `grpc_gateway` or REST transcoding
