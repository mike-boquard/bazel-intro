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
| 2 | A quick word from our sponsor — experience, disclaimers, honest pros/cons |
| 3 | Agenda |
| 4 | Why Bazel — hermetic, incremental, polyglot |
| 5 | How Bazel works — JVM server, three build phases, sandboxed actions |
| 6 | Core vocabulary — workspace / package / target / rule |
| 7 | What is Bzlmod? — MODULE.bazel replaces WORKSPACE |
| 8 | MODULE.bazel in practice — bazel_dep, use_extension, use_repo |
| 9 | BCR — Bazel Central Registry |
| 10 | Non-BCR deps — spdlog via http_archive module extension |
| 11 | C++ BUILD file — cc_library, cc_binary, cc_test |
| 12 | C++ commands — build, run, test |
| 13 | Go + rules_go + Gazelle |
| 14 | Proto file — greeter.proto |
| 15 | Proto BUILD — proto_library, cc_grpc_library, go_proto_library |
| 16 | Cross-language — C++ server + Go client |
| 17 | Integration test — sh_test wiring server and client |
| 18 | Testing — bazel test commands, --test_filter, --runs_per_test, caching |
| 19 | GoogleTest integration — cc_test + @googletest//:gtest_main, BCR dep, sandbox, vs CMake |
| 20 | Caching comparison — Ninja/CMake vs Bazel |
| 21 | Caching config — disk cache + CI restore-keys |
| 22 | Querying the build graph — query, cquery, aquery |
| 23 | Dev ergonomics — clangd, rust-analyzer, gopls, buildifier |
| 24 | Hermetic Python — rules_python, pip.parse, requirements_lock.txt |
| 25 | Rust — rules_rust, crate_universe, inline #[cfg(test)] tests, colored crate |
| 26 | Takeaways |
| 27 | FAQ divider |
| 28 | FAQ: Pinning a Clang version (toolchains_llvm, --config=clang) |
| 29 | FAQ: clang-format via @llvm_toolchain — format_cpp.sh, .clang-format, //:clang-format alias |
| 30 | FAQ: Custom flags & sanitizers |
| 31 | FAQ: Cross-compilation |
| 32 | FAQ: Migrating from CMake |
| 33 | FAQ: System & vendored deps |
| 34 | FAQ: Go specifics |
| 35 | FAQ: Performance & remote execution |
| 36 | FAQ: Rough edges |
| 37 | Q&A |
