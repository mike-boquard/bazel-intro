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
bazel query 'deps(//cpp/app:app)' --output label 2>/dev/null | grep -v '^@'
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
//:refresh_compile_commands (0c99c1c)
//:refresh_compile_commands.check_python_version.py (0c99c1c)
//:refresh_compile_commands.py (0c99c1c)
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

The `--output=text` format is verbose — each action includes its inputs, outputs, and full command line. Piping through `grep 'Mnemonic:'` extracts just the action type names for a quick overview:

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
| `--output=label`, `--output=graph`, `--output=build` | Alternative output formats | `label` for scripting, `graph` for Graphviz visualization, `build` to see reconstructed BUILD syntax |
