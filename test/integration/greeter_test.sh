#!/usr/bin/env bash
# Integration test: starts the C++ gRPC server, calls it from the Go client,
# asserts the response is "Hello, World!".
set -euo pipefail

[[ $# -eq 2 ]] || { echo "Usage: $0 <server-bin> <client-bin>"; exit 1; }

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
