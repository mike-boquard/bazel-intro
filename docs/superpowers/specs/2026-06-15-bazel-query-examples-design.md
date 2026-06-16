# Bazel Query Examples Design

**Date:** 2026-06-15
**Status:** Approved

## Goal

Create `docs/bazel-query-examples.md` — a single document that teaches the three
Bazel query tools (`query`, `cquery`, `aquery`) through real examples drawn from
this repo's targets. Serves both as a learning reference (what each tool does and
when to reach for it) and as a quick-reference cheatsheet.

## File

Single file: `docs/bazel-query-examples.md`

No source code changes. No new BUILD targets. Pure documentation.

## Structure

### Intro (~3 sentences)

States that Bazel exposes three query tools for inspecting the build graph at
different levels of detail, and links to the official Bazel query docs. Tells
the reader all examples can be run from this repo as-is.

Official docs links:
- https://bazel.build/query/guide
- https://bazel.build/query/cquery
- https://bazel.build/query/aquery

---

### Section 1 — `bazel query` (static graph)

**What it does:** Reads BUILD files without running any analysis or build.
Answers questions about the static dependency graph: what targets exist, what
depends on what, what is the path between two nodes.

**When to use it:** Finding targets, exploring deps, understanding who uses a
library — no build required.

**Examples** (each with the command and its actual output):

1. List all targets in the workspace:
   ```
   bazel query '//...'
   ```
   Output: all 9 targets in the workspace.

2. List targets in a single package:
   ```
   bazel query '//cpp/...'
   ```

3. Find everything that depends on `//cpp/greeter:greeter` (reverse deps):
   ```
   bazel query 'rdeps(//..., //cpp/greeter:greeter)'
   ```
   Output: `//cpp/app:app`, `//cpp/greeter:greeter`, `//cpp/greeter:greeter_test`

4. Find all transitive deps of `//cpp/app:app` (workspace targets only):
   ```
   bazel query 'deps(//cpp/app:app)' --output label
   ```
   (Truncated to workspace-only with `grep -v "^@"` for readability.)

5. Find the dependency path between two targets (`somepath`):
   ```
   bazel query 'somepath(//cpp/app:app, @abseil-cpp//absl/strings:strings)'
   ```
   Output: `//cpp/app:app → //cpp/greeter:greeter → @abseil-cpp//absl/strings:strings`

6. Filter targets by rule kind:
   ```
   bazel query 'kind(cc_test, //...)'
   ```
   Output: `//cpp/greeter:greeter_test`

7. Filter targets by name pattern:
   ```
   bazel query 'filter("greeter", //...)'
   ```

---

### Section 2 — `bazel cquery` (configured graph)

**What it does:** Runs after Bazel's analysis phase, so it understands build
configurations (`--platforms`, `--compilation_mode`, `select()` branches). Each
target is shown with its configuration hash.

**When to use it:** When you need to understand which variant of a target gets
built under a given set of flags, or to inspect `select()` resolution.

**Examples:**

1. List all targets with their configuration hashes:
   ```
   bazel cquery '//...'
   ```
   Output shows hashes like `(0c99c1c)` — binaries/libraries share one hash,
   tests get a different one (test configuration).

2. Show deps of a test target with their configurations:
   ```
   bazel cquery 'deps(//cpp/greeter:greeter_test)'
   ```
   Illustrates how `greeter_test` (test config `796b1f2`) depends on `greeter`
   (default config `0c99c1c`), showing configuration transitions.

3. Brief callout: `cquery` vs `query` — `query` would show both configs as one
   node; `cquery` shows them separately. Useful when a dep is pulled in under
   multiple configurations.

---

### Section 3 — `bazel aquery` (action graph)

**What it does:** Exposes the actual build actions — the compiler invocations,
linker commands, file writes — that Bazel would execute. Shows inputs, outputs,
mnemonics, and the full command line.

**When to use it:** Debugging what flags are being passed to the compiler,
verifying that a build action uses the expected inputs, or understanding why an
incremental build is or isn't cached.

**Examples:**

1. Show all actions for a target (mnemonic list):
   ```
   bazel aquery '//cpp/greeter:greeter' --output=text
   ```
   Mnemonics seen: `CppModuleMap`, `CppCompile`, `FileWrite`, `CppArchive`.

2. Filter to a specific action type using `mnemonic()`:
   ```
   bazel aquery 'mnemonic("CppCompile", //cpp/greeter:greeter)' --output=text
   ```
   Shows the single `CppCompile` action: full inputs list (source, headers,
   abseil headers) and outputs (`greeter.o`, `greeter.d`).

3. One-liner to extract just the compiler command line from the action:
   ```
   bazel aquery 'mnemonic("CppCompile", //cpp/greeter:greeter)' \
     --output=text 2>/dev/null | grep -A1 "Command Line"
   ```

---

### Quick-Reference Table

10-row table, three columns: **Expression / Flag**, **What it answers**,
**When to use it**.

Rows:
| Expression | What it answers | When to use it |
|---|---|---|
| `bazel query '//...'` | All targets in the workspace | Getting a lay of the land |
| `bazel query 'deps(T)'` | Transitive deps of T | Understanding what T pulls in |
| `bazel query 'rdeps(//..., T)'` | Everything that depends on T | Finding consumers before changing T |
| `bazel query 'somepath(A, B)'` | One dependency path from A to B | Tracing why A depends on B |
| `bazel query 'allpaths(A, B)'` | All paths from A to B | Full reachability between two targets |
| `bazel query 'kind(rule, //...)'` | Targets matching a rule type | Finding all `cc_test` or `go_binary` targets |
| `bazel query 'filter("pat", //...)'` | Targets whose label matches a regex | Finding targets by name pattern |
| `bazel cquery '//...'` | Targets with their config hashes | Seeing how configs differ across targets |
| `bazel aquery 'mnemonic("X", T)'` | Actions of type X for target T | Inspecting compiler/linker flags |
| `--output=label \| graph \| build` | Alternative output formats | Machine-readable or dot-graph output |

## What is NOT in scope

- `bazel mod graph` (Bzlmod module graph, not build graph)
- `--output=proto` or streaming JSON output formats
- Writing custom query functions or Starlark extensions
- `bazel query` over external repositories (beyond showing `@abseil-cpp` in somepath output)
