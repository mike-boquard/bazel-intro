# Bazel Query Examples Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `docs/bazel-query-examples.md` — a single markdown file teaching `bazel query`, `bazel cquery`, and `bazel aquery` through real examples from this repo, doubling as a quick-reference cheatsheet.

**Architecture:** Pure documentation, no source code changes. One file created. All query commands have been pre-run against the repo; expected outputs are embedded in the plan so the implementer can verify them locally and write accurate examples.

**Tech Stack:** Markdown, Bazel query language, this repo's real targets.

---

## File Map

| File | Change |
|------|--------|
| `docs/bazel-query-examples.md` | Create — full query reference doc |

---

## Task 1: Create `docs/bazel-query-examples.md`

**Files:**
- Create: `docs/bazel-query-examples.md`

This is the entire deliverable. The file content is specified completely below.

- [ ] **Step 1: Verify the expected query outputs match the repo**

Run each command below from `/Users/mboquard/dev/bazel-intro` and confirm the output matches what's shown. This ensures the doc is accurate before writing it.

```bash
bazel query '//...'
```
Expected (order may vary):
```
//:refresh_compile_commands
//:refresh_compile_commands.check_python_version.py
//:refresh_compile_commands.py
//cpp/app:app
//cpp/greeter:greeter
//cpp/greeter:greeter_test
//go/app:app
//go/greeter:greeter
//go/greeter:greeter_test
```

```bash
bazel query '//cpp/...'
```
Expected:
```
//cpp/app:app
//cpp/greeter:greeter
//cpp/greeter:greeter_test
```

```bash
bazel query 'rdeps(//..., //cpp/greeter:greeter)'
```
Expected:
```
//cpp/app:app
//cpp/greeter:greeter
//cpp/greeter:greeter_test
```

```bash
bazel query 'deps(//cpp/app:app)' --output label | grep -v '^@'
```
Expected (order may vary):
```
//cpp/app:app
//cpp/app:main.cc
//cpp/greeter:greeter
//cpp/greeter:greeter.cc
//cpp/greeter:greeter.h
```

```bash
bazel query 'somepath(//cpp/app:app, @abseil-cpp//absl/strings:strings)'
```
Expected:
```
//cpp/app:app
//cpp/greeter:greeter
@abseil-cpp//absl/strings:strings
```

```bash
bazel query 'kind(cc_test, //...)'
```
Expected:
```
//cpp/greeter:greeter_test
```

```bash
bazel query 'filter("greeter", //...)'
```
Expected:
```
//cpp/greeter:greeter
//cpp/greeter:greeter_test
//go/greeter:greeter
//go/greeter:greeter_test
```

```bash
bazel cquery '//...'
```
Expected (config hashes may differ on your machine, but two distinct hashes should appear — one for binaries/libraries, one for tests):
```
//cpp/app:app (0c99c1c)
//cpp/greeter:greeter (0c99c1c)
//cpp/greeter:greeter_test (796b1f2)
//go/app:app (0c99c1c)
//go/greeter:greeter (0c99c1c)
//go/greeter:greeter_test (796b1f2)
//:refresh_compile_commands (0c99c1c)
...
```

```bash
bazel aquery '//cpp/greeter:greeter' --output=text 2>/dev/null | grep 'Mnemonic:'
```
Expected:
```
  Mnemonic: CppModuleMap
  Mnemonic: CppCompile
  Mnemonic: FileWrite
  Mnemonic: CppArchive
```

If outputs differ significantly, update the doc to match actual output rather than using stale values from this plan.

- [ ] **Step 2: Create `docs/bazel-query-examples.md`**

Create the file with this exact content (substitute the config hashes in the `cquery` examples with whatever your local run produced in Step 1):

````markdown
# Bazel Query Examples

Bazel exposes three query tools for inspecting the build graph at different levels
of detail. All examples below run against this repo as-is — no build required for
`query`, and only analysis (no compilation) for `cquery` and `aquery`.

Official docs:
- [`bazel query`](https://bazel.build/query/guide) — static graph
- [`bazel cquery`](https://bazel.build/query/cquery) — configured graph
- [`bazel aquery`](https://bazel.build/query/aquery) — action graph

---

## `bazel query` — Static Dependency Graph

Reads BUILD files without running analysis or compilation. Use it to find targets,
explore dependencies, and understand the shape of the graph before building anything.

### List all targets in the workspace

```bash
bazel query '//...'
```

```
//:refresh_compile_commands
//:refresh_compile_commands.check_python_version.py
//:refresh_compile_commands.py
//cpp/app:app
//cpp/greeter:greeter
//cpp/greeter:greeter_test
//go/app:app
//go/greeter:greeter
//go/greeter:greeter_test
```

### List targets in a single package subtree

```bash
bazel query '//cpp/...'
```

```
//cpp/app:app
//cpp/greeter:greeter
//cpp/greeter:greeter_test
```

### Find everything that depends on a target (reverse deps)

Useful before changing a library: see who will be affected.

```bash
bazel query 'rdeps(//..., //cpp/greeter:greeter)'
```

```
//cpp/app:app
//cpp/greeter:greeter
//cpp/greeter:greeter_test
```

### Find transitive deps of a target (workspace targets only)

```bash
bazel query 'deps(//cpp/app:app)' --output label | grep -v '^@'
```

```
//cpp/app:app
//cpp/app:main.cc
//cpp/greeter:greeter
//cpp/greeter:greeter.cc
//cpp/greeter:greeter.h
```

The `grep -v '^@'` filters out external repository deps (abseil headers, spdlog,
etc.) to keep the output readable. Remove the filter to see the full transitive
closure including external deps.

### Trace the dependency path between two targets

`somepath` returns one path; `allpaths` returns every path.

```bash
bazel query 'somepath(//cpp/app:app, @abseil-cpp//absl/strings:strings)'
```

```
//cpp/app:app
//cpp/greeter:greeter
@abseil-cpp//absl/strings:strings
```

This shows that `//cpp/app:app` pulls in abseil through `//cpp/greeter:greeter`,
not directly.

### Filter targets by rule type

```bash
bazel query 'kind(cc_test, //...)'
```

```
//cpp/greeter:greeter_test
```

Other useful rule kinds: `go_test`, `cc_binary`, `go_binary`, `cc_library`.

### Filter targets by name pattern

```bash
bazel query 'filter("greeter", //...)'
```

```
//cpp/greeter:greeter
//cpp/greeter:greeter_test
//go/greeter:greeter
//go/greeter:greeter_test
```

`filter` matches against the full label string using a regex.

---

## `bazel cquery` — Configured Dependency Graph

Runs after Bazel's analysis phase, so it understands build configurations:
`--platforms`, `--compilation_mode`, and `select()` branch resolution. Each
result is annotated with a configuration hash.

Use `cquery` when `query` gives you ambiguous results because the same target
is built under multiple configurations (e.g., a library depended on by both a
binary and a test).

### List all targets with their configuration hashes

```bash
bazel cquery '//...'
```

```
//cpp/app:app (0c99c1c)
//cpp/greeter:greeter (0c99c1c)
//cpp/greeter:greeter_test (796b1f2)
//go/app:app (0c99c1c)
//go/greeter:greeter (0c99c1c)
//go/greeter:greeter_test (796b1f2)
```

Two distinct hashes appear: one for the default build configuration (binaries and
libraries) and one for the test configuration (targets built under `bazel test`).
The exact hashes on your machine may differ from the above.

### Show deps of a test target with configurations

```bash
bazel cquery 'deps(//cpp/greeter:greeter_test)'
```

```
//cpp/greeter:greeter_test (796b1f2)
//cpp/greeter:greeter (0c99c1c)
//cpp/greeter:greeter_test.cc (null)
//cpp/greeter:greeter.cc (null)
//cpp/greeter:greeter.h (null)
```

Notice that `greeter_test` (test config `796b1f2`) depends on `greeter` compiled
in the default config (`0c99c1c`). Source files show `null` — they have no
configuration because they are not built targets, just inputs. `bazel query`
would collapse both config variants into a single node; `cquery` shows them
separately, which matters when a library is pulled in by both test and non-test
targets with different flag sets.

---

## `bazel aquery` — Action Graph

Shows the actual build actions Bazel would execute: compiler invocations, linker
commands, file writes. Use it to inspect compiler flags, verify inputs and outputs,
or understand why an incremental build is or isn't reusing a cached action.

### List all actions for a target

```bash
bazel aquery '//cpp/greeter:greeter' --output=text 2>/dev/null | grep 'Mnemonic:'
```

```
  Mnemonic: CppModuleMap
  Mnemonic: CppCompile
  Mnemonic: FileWrite
  Mnemonic: CppArchive
```

Each mnemonic is one build action: generating the module map, compiling the `.cc`
file, writing auxiliary files, and archiving into a `.a` static library.

### Inspect a specific action's inputs and outputs

Filter to the `CppCompile` action to see exactly what the compiler reads and writes:

```bash
bazel aquery 'mnemonic("CppCompile", //cpp/greeter:greeter)' --output=text 2>/dev/null
```

The output shows:
- **Inputs:** `greeter.cc`, `greeter.h`, all transitive abseil headers, toolchain
  files
- **Outputs:** `greeter.o` and `greeter.d` (dependency file) under
  `bazel-out/…/bin/cpp/greeter/_objs/greeter/`
- **Command Line:** the full compiler invocation with every flag

### Extract just the compiler command line

```bash
bazel aquery 'mnemonic("CppCompile", //cpp/greeter:greeter)' \
  --output=text 2>/dev/null | grep -A1 "Command Line"
```

Useful for debugging unexpected compiler flags or verifying that `-std=c++17`
(set in `.bazelrc`) is being applied.

---

## Quick Reference

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
````

- [ ] **Step 3: Verify all commands in the doc run cleanly**

From `/Users/mboquard/dev/bazel-intro`, run a spot-check of three commands:

```bash
bazel query 'kind(cc_test, //...)'
bazel cquery '//...' 2>/dev/null | grep greeter
bazel aquery 'mnemonic("CppCompile", //cpp/greeter:greeter)' --output=text 2>/dev/null | grep 'Mnemonic:'
```

Expected:
```
//cpp/greeter:greeter_test

//cpp/greeter:greeter (0c99c1c)
//cpp/greeter:greeter_test (796b1f2)

  Mnemonic: CppCompile
```

If any command errors, fix the doc before committing.

- [ ] **Step 4: Commit**

```bash
cd /Users/mboquard/dev/bazel-intro
git add docs/bazel-query-examples.md
git commit -s -m "docs: add bazel query/cquery/aquery examples"
```

---

## Verification

After the commit, confirm:

```bash
# File exists
ls docs/bazel-query-examples.md

# All three query tools work
bazel query '//...' > /dev/null && echo "query ok"
bazel cquery '//...' > /dev/null 2>&1 && echo "cquery ok"
bazel aquery '//cpp/greeter:greeter' --output=text > /dev/null 2>&1 && echo "aquery ok"
```

Expected:
```
docs/bazel-query-examples.md
query ok
cquery ok
aquery ok
```
