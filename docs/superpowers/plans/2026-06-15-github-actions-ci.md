# GitHub Actions CI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a GitHub Actions workflow that runs `bazel test //...` on every push to `main` and every pull request, with Bazel disk cache persisted via `actions/cache`.

**Architecture:** Two changes — one line added to `.bazelrc` to enable Bazel's disk cache, and one workflow file at `.github/workflows/ci.yml`. The disk cache line must land before the workflow so CI uses caching from the first run.

**Tech Stack:** GitHub Actions, bazelisk, Bazel 7.4.1, `actions/cache@v4`

---

## File Map

| File | Change |
|------|--------|
| `.bazelrc` | Add `build --disk_cache=~/.cache/bazel/disk-cache` |
| `.github/workflows/ci.yml` | Create CI workflow |

---

## Task 1: Enable Bazel Disk Cache in .bazelrc

**Files:**
- Modify: `.bazelrc`

- [ ] **Step 1: Add disk cache line to `.bazelrc`**

The current `.bazelrc` ends with `test --test_output=errors`. Add a new section
after `# Build UX` — or append at the end. Complete new file:

```
# Build correctness
build --cxxopt=-std=c++17

# Build UX
build --verbose_failures
build --color=yes
build --keep_going

# CI / caching
# Enables Bazel's local disk cache. When ~/.cache/bazel is restored by
# actions/cache in CI, Bazel reuses previous build outputs and skips
# re-downloading external deps.
build --disk_cache=~/.cache/bazel/disk-cache

# Test UX
test --test_output=errors
```

- [ ] **Step 2: Verify the disk cache flag is accepted**

```bash
cd /Users/mboquard/dev/bazel-intro && bazel test //...
```

Expected: tests still pass. Bazel will create `~/.cache/bazel/disk-cache/`
on the first run with this flag.

- [ ] **Step 3: Commit**

```bash
cd /Users/mboquard/dev/bazel-intro
git add .bazelrc
git commit -s -m "build: enable Bazel disk cache for CI caching"
```

---

## Task 2: Add GitHub Actions Workflow

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create `.github/workflows/ci.yml`**

```bash
mkdir -p /Users/mboquard/dev/bazel-intro/.github/workflows
```

File content:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Cache Bazel outputs
        uses: actions/cache@v4
        with:
          path: ~/.cache/bazel
          key: ${{ runner.os }}-bazel-${{ hashFiles('MODULE.bazel.lock') }}
          restore-keys: |
            ${{ runner.os }}-bazel-

      - name: Install bazelisk
        run: |
          curl -Lo /usr/local/bin/bazel \
            https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64
          chmod +x /usr/local/bin/bazel

      - name: Test
        run: bazel test //...
```

- [ ] **Step 2: Lint-check the YAML locally**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo "YAML valid"
```

Expected: `YAML valid`

If `yaml` module is missing: `pip3 install pyyaml` then re-run.

- [ ] **Step 3: Verify `bazel test //...` still passes locally (sanity check)**

```bash
cd /Users/mboquard/dev/bazel-intro && bazel test //...
```

Expected:
```
//cpp/greeter:greeter_test    PASSED
//go/greeter:greeter_test     PASSED
Executed 0 out of 2 tests: 2 tests pass.
```

- [ ] **Step 4: Update README.md to mention CI**

Add a CI badge line at the very top of `README.md`, just below the `# bazel-intro` heading.
Replace `YOUR_GITHUB_USERNAME` with your actual GitHub username once the repo is pushed:

```markdown
# bazel-intro

[![CI](https://github.com/YOUR_GITHUB_USERNAME/bazel-intro/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_GITHUB_USERNAME/bazel-intro/actions/workflows/ci.yml)
```

- [ ] **Step 5: Commit**

```bash
cd /Users/mboquard/dev/bazel-intro
git add .github/ README.md
git commit -s -m "ci: add GitHub Actions workflow with Bazel disk cache"
```

---

## Verification

After both tasks are committed:

```bash
# Local tests still pass
bazel test //...

# Workflow file is valid YAML
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo "YAML valid"

# Disk cache directory was created by Bazel
ls ~/.cache/bazel/disk-cache/
```

Once pushed to GitHub, CI runs automatically. Check the Actions tab to confirm
the workflow appears and the first run succeeds. Subsequent runs will be faster
as the cache warms up.
