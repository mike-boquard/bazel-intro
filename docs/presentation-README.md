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
| 4 | Core vocabulary — workspace / package / target / rule |
| 5 | What is Bzlmod? — MODULE.bazel replaces WORKSPACE |
| 6 | MODULE.bazel in practice — bazel_dep, use_extension, use_repo |
| 7 | BCR — Bazel Central Registry |
| 8 | Non-BCR deps — spdlog via http_archive module extension |
| 9 | C++ BUILD file — cc_library, cc_binary, cc_test |
| 10 | C++ commands — build, run, test |
| 11 | Go + rules_go + Gazelle |
| 12 | Proto file — greeter.proto |
| 13 | Proto BUILD — proto_library, cc_grpc_library, go_proto_library |
| 14 | Cross-language — C++ server + Go client |
| 15 | Integration test — sh_test wiring server and client |
| 16 | Testing — bazel test commands, --test_filter, --runs_per_test, caching |
| 17 | GoogleTest integration — cc_test + @googletest//:gtest_main, BCR dep, sandbox, vs CMake |
| 18 | Caching comparison — Ninja/CMake vs Bazel |
| 19 | Caching config — disk cache + CI restore-keys |
| 20 | Querying the build graph — query, cquery, aquery |
| 21 | Dev ergonomics — clangd / compile_commands.json |
| 22 | Hermetic Python — rules_python, pip.parse, requirements_lock.txt |
| 23 | Rust — rules_rust, crate_universe, inline #[cfg(test)] tests, colored crate |
| 24 | Takeaways |
| 25 | FAQ divider |
| 26 | FAQ: Pinning a Clang version (toolchains_llvm, --config=clang) |
| 27 | FAQ: Custom flags & sanitizers |
| 28 | FAQ: Cross-compilation |
| 29 | FAQ: Migrating from CMake |
| 30 | FAQ: System & vendored deps |
| 31 | FAQ: Go specifics |
| 32 | FAQ: Performance & remote execution |
| 33 | FAQ: Rough edges |
| 34 | Q&A |
