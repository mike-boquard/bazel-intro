# GitHub Actions CI Design

**Date:** 2026-06-15
**Status:** Approved

## Goal

Run `bazel test //...` on every push to `main` and on every pull request, with
Bazel disk cache persisted via `actions/cache` so subsequent runs are fast.

## Workflow file

Single file: `.github/workflows/ci.yml`

Triggers:
- `push` to `main`
- `pull_request` (all branches)

Runner: `ubuntu-latest`

## Steps

1. `actions/checkout@v4`
2. `actions/cache@v4` — cache `~/.cache/bazel`, keyed on:
   `<os>-bazel-<hash of MODULE.bazel.lock>`
   Restores the most recent matching cache on cache miss (restore-keys fallback).
3. Install bazelisk via `curl` to `/usr/local/bin/bazel` — makes `bazel` on PATH
   resolve to bazelisk, which reads `.bazelversion` and downloads Bazel 7.4.1.
4. `bazel test //...`

## .bazelrc change

Add one line to activate Bazel's disk cache so `actions/cache` captures build
outputs in addition to downloaded repositories:

```
build --disk_cache=~/.cache/bazel/disk-cache
```

## Cache key strategy

Key: `ubuntu-latest-bazel-<hashFiles('MODULE.bazel.lock')>`
Restore key: `ubuntu-latest-bazel-`

`MODULE.bazel.lock` is used rather than `MODULE.bazel` because the lock file
changes exactly when dependencies change (adding a dep, bumping a version),
making it the most precise signal for cache invalidation.

## What is NOT in scope

- macOS or Windows runners
- Smoke-running the binaries (`bazel run //cpp/app:app`)
- Remote caching (Bazel remote cache / BuildBuddy / EngFlow)
- Matrix builds across multiple Bazel versions
