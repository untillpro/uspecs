# sys tests: split setup() into layered helpers so tests that do not need git skip git init/origin

- URL: https://github.com/untillpro/uspecs/issues/93
- ID: #93
- State: open
- Author: @maxim-ge
- Labels: none

## Problem

`tests/sys/helpers.bash` defines a single `setup()` that runs for every sys test and unconditionally:

- mirrors `bin/` into an isolated `$PROJECT_ROOT`
- runs `git init` + initial commit
- runs `git init --bare` for an `origin` remote
- pushes `main` and sets upstream

There are ~120 sys tests across 11 `.bats` files. A non-trivial number of them do not need git at all (e.g. `softeng.sh.bats`, `softeng.sh-action-uversion.bats`, many `uchange` scenarios that only validate argument parsing and emitted directives) or do not need an `origin` remote (most `uimpl`, `uarchive`, `usync`, `wcf-list`, `diff` scenarios that only operate on a local branch).

Several tests even start with `rm -rf "$PROJECT_ROOT/.git"` to undo the heavy setup just to assert the "no git repository" error path - pure waste.

The `softeng.sh-self-review.bats` file already shows the precedent of overriding `setup()` with a minimal version because the command is read-only.

## Proposal (option 1 from the discussion)

Split `setup()` into layered helpers and have each test call only what it needs.

### New shape of `tests/sys/helpers.bash`

```bash
setup() {
    # cheap: mirror bin/, create uspecs/{changes,specs}, gh stub on PATH
    _setup_project_root
    _setup_gh_stub
}

_setup_git_repo()   { ... git init + user config + initial commit ... }
_setup_git_origin() { _setup_git_repo; ... bare origin + push + upstream ... }
```

`_setup_git_origin` implies `_setup_git_repo` (idempotent guard so calling both is safe).

### Per-test classification

Each `@test` (or per-file via `setup_file`/override) declares its needs by calling the appropriate helper as the first line:

- no call: tests that only invoke `uspecs` and inspect stdout/stderr (e.g. `uversion`, unknown-command, most `uchange` branch-name formatting scenarios, "no git repository" negative paths)
- `_setup_git_repo`: tests that need a local branch / commit but no remote (most `uimpl`, `uarchive`, `usync`, `wcf-list`, `diff`)
- `_setup_git_origin`: tests that push or read upstream (`upr`, `umergepr`, parts of `usync`)

For files where every test in the file needs the same level, override `setup()` at file scope to call the appropriate helper, mirroring the existing `self-review` pattern.

## Expected benefits

- Faster sys test suite (skip 2x `git init`, a commit, a push, and config writes for tests that do not need them).
- "No git repository" tests stop fighting against their own setup.
- Each test's preconditions become explicit and documented at the call site.

## Out of scope

- Caching an initialized template via `setup_file()` (option 3 in the discussion) - can be layered on top later if further speedup is wanted.
- Changes to `tests/unit` or `tests/e2e` helpers.

## Acceptance criteria

- `tests/sys/helpers.bash` exposes `_setup_project_root`, `_setup_gh_stub`, `_setup_git_repo`, `_setup_git_origin` (names tentative).
- Default `setup()` in `helpers.bash` only does the cheap project-root + gh-stub work.
- Every existing sys test is audited and either calls the appropriate helper or relies on a file-level `setup()` override.
- All sys tests still pass: `tests/run-tests.py sys`.
- Tests that previously did `rm -rf "$PROJECT_ROOT/.git"` no longer need to.
