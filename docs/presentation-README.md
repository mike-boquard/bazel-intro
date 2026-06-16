# Presentation

Slides for the Bazel introductory talk, built with [Reveal.js](https://revealjs.com).

**File:** `docs/presentation.html`

## How to open

### Quickest: open directly in a browser

```bash
open docs/presentation.html        # macOS
xdg-open docs/presentation.html   # Linux
```

The file loads Reveal.js from a CDN, so you need an internet connection the first time. After that, the browser caches the CDN assets.

### Local server (avoids any browser file:// restrictions)

```bash
python3 -m http.server 8000 --directory .
# then open http://localhost:8000/docs/presentation.html
```

## Controls

| Key | Action |
|-----|--------|
| `→` / `Space` | Next slide |
| `←` | Previous slide |
| `f` | Fullscreen |
| `s` | Speaker notes view |
| `Esc` | Slide overview |
| `?` | All keyboard shortcuts |

## Slide overview

| # | Section |
|---|---------|
| 1 | Title |
| 2 | Agenda |
| 3 | Why Bazel — hermetic, incremental, polyglot |
| 4 | How Bazel works — JVM server, three build phases, sandboxed actions |
| 5 | Core vocabulary — workspace / package / target / rule |
| 6 | What is Bzlmod? — MODULE.bazel replaces WORKSPACE |
| 7 | MODULE.bazel in practice — bazel_dep, use_extension, use_repo |
| 8 | BCR — Bazel Central Registry |
| 9 | Non-BCR deps — spdlog via http_archive module extension |
| 10 | C++ BUILD file — cc_library, cc_binary, cc_test |
| 11 | C++ commands — build, run, test |
| 12 | Go + rules_go + Gazelle |
| 13 | Proto file — greeter.proto |
| 14 | Proto BUILD — proto_library, cc_grpc_library, go_proto_library |
| 15 | Cross-language — C++ server + Go client |
| 16 | Integration test — sh_test wiring server and client |
| 17 | Testing — bazel test commands, --test_filter, --runs_per_test, caching |
| 18 | GoogleTest integration — cc_test + @googletest//:gtest_main, BCR dep, sandbox, vs CMake |
| 19 | Caching comparison — Ninja/CMake vs Bazel |
| 20 | Caching config — disk cache + CI restore-keys |
| 21 | Querying the build graph — query, cquery, aquery |
| 22 | Dev ergonomics — clangd / compile_commands.json |
| 23 | Hermetic Python — rules_python, pip.parse, requirements_lock.txt |
| 24 | Rust — rules_rust, crate_universe, inline #[cfg(test)] tests, colored crate |
| 25 | Takeaways |
| 26 | FAQ divider |
| 27 | FAQ: Pinning a Clang version (toolchains_llvm, --config=clang) |
| 28 | FAQ: clang-format via @llvm_toolchain — format_cpp.sh, .clang-format, //:clang-format alias |
| 29 | FAQ: Custom flags & sanitizers |
| 30 | FAQ: Cross-compilation |
| 31 | FAQ: Migrating from CMake |
| 32 | FAQ: System & vendored deps |
| 33 | FAQ: Go specifics |
| 34 | FAQ: Performance & remote execution |
| 35 | FAQ: Rough edges |
| 36 | Q&A |
