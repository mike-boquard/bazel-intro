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
# Python (no install needed)
python3 -m http.server 8000 --directory .
# then open http://localhost:8000/docs/presentation.html
```

## Controls

| Key | Action |
|-----|--------|
| `→` / `Space` | Next slide |
| `←` | Previous slide |
| `↑` / `↓` | Navigate vertical slides (sub-sections) |
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
| 5 | Bzlmod, MODULE.bazel, BCR |
| 6 | Non-BCR deps via module extension (spdlog) |
| 7 | C++ library + binary + tests |
| 8 | Go + rules_go + Gazelle |
| 9 | Cross-language: Proto / gRPC |
| 10 | Testing — unit, integration, sh_test |
| 11 | Caching — disk cache + CI |
| 12 | Querying the build graph |
| 13 | Dev ergonomics — clangd / compile_commands.json |
| 14 | Takeaways |
| 15 | Q&A |
