---
registered_at: 2026-05-20T09:31:47Z
change_id: 2605200931-sys-tests-layered-setup-helpers
type: test
scope: dev
baseline: ab28c180d63ba1d88629a67e0ac0816609196fe1
issue_url: https://github.com/untillpro/uspecs/issues/93
archived_at: 2026-05-20T13:25:18Z
---

# Change request: Split sys test setup() into layered helpers

## Context

The shared `tests/sys/helpers.bash` `setup()` unconditionally initializes a project root, a local git repo, and a bare `origin` remote for every sys test, even though many of the ~120 sys tests do not need git or a remote (some even `rm -rf .git` to undo it). Restructure `setup()` into layered helpers (`_setup_project_root`, `_setup_gh_stub`, `_setup_git_repo`, `_setup_git_origin`) so each test opts in only to what it needs, speeding up the sys suite and making per-test preconditions explicit. Caching a template via `setup_file()` is out of scope.

Current results for sys tests: 120 tests, 0 failures, 125.0s.

See [issue.md](issue.md) for the originating ticket.

## How

Decisions:

- Split the current monolithic `setup()` in `tests/sys/helpers.bash` into four named helpers: `_setup_project_root`, `_setup_gh_stub`, `_setup_git_repo`, `_setup_git_origin`

- Default `setup()` calls only `_setup_project_root` + `_setup_gh_stub` (cheap work: mirror `bin/`, create `uspecs/{changes,specs}`, put `gh` stub on PATH)

- Tests requiring git opt in by calling `_setup_git_repo` as the first line; tests requiring a remote call `_setup_git_origin` (which internally ensures `_setup_git_repo` ran, so calling both is safe)

- Where every test in a file needs the same level, override `setup()` at file scope, following the precedent already set by `tests/sys/softeng.sh-self-review.bats`

- Audit each existing `@test` and add the appropriate helper call (or file-level override); drop now-redundant `rm -rf "$PROJECT_ROOT/.git"` lines in "no git repository" negative-path tests

- Tests using `_make_change_folder` implicitly require git (it does `git add` + `git commit`); they must call `_setup_git_repo` (or `_setup_git_origin`) before the first `_make_change_folder` invocation. `_make_change_folder` itself is not modified

Out of scope:

- Caching an initialized project template via `setup_file()` (option 3 in the issue discussion)
- Changes to `tests/unit` or `tests/e2e` helpers
- Refactoring the `uspecs()` runner or `_make_change_folder` helper

References:

- [sys test helpers](../../../../../tests/sys/helpers.bash)
- [self-review setup() override precedent](../../../../../tests/sys/softeng.sh-self-review.bats)
- [sys tests directory](../../../../../tests/sys)
- [run-tests entrypoint](../../../../../tests/run-tests.py)

## Construction

- [x] update: [tests/sys/helpers.bash](../../../../../tests/sys/helpers.bash)
  - extract `_setup_project_root`: Windows `OSTYPE`/`cygpath` tmpdir conversion, `PROJECT_ROOT` export, `bin/` mirror, `uspecs/{changes,specs}` mkdir, and `cd "$PROJECT_ROOT"` (so tests get cwd even without git)
  - extract `_setup_gh_stub`: `chmod +x` + PATH prefix for `gh` stub
  - extract `_setup_git_repo`: `git init` + user config + initial commit (idempotent: no-op if `$PROJECT_ROOT/.git` already exists)
  - extract `_setup_git_origin`: bare `origin` repo + push + upstream (calls `_setup_git_repo` first; idempotent)
  - update default `setup()` to call only `_setup_project_root` and `_setup_gh_stub`
  - update `_make_change_folder` header comment to document that callers must have run `_setup_git_repo` (or `_setup_git_origin`) first, since it does `git add` + `git commit`

- [x] update: [tests/sys/softeng.sh.bats](../../../../../tests/sys/softeng.sh.bats)
  - 1 test (unknown-command usage error): no helper call needed, uses the cheap default

- [x] update: [tests/sys/softeng.sh-action-uversion.bats](../../../../../tests/sys/softeng.sh-action-uversion.bats)
  - 2 tests (read-only `uversion`): no helper calls needed, uses the cheap default

- [x] update: [tests/sys/softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - add `_setup_git_repo` only to tests that need a commit/branch; leave argument-parsing and branch-name-formatting tests with the cheap default

- [x] update: [tests/sys/softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
  - 20 tests, all use `_make_change_folder` or `git checkout`: file-level `setup()` override calling `_setup_git_origin` (uimpl's WCF detection resolves against `origin/<default-branch>` via `wcf_list`'s merge-base lookup, so a local-only repo is insufficient)

- [x] update: [tests/sys/softeng.sh-action-uarchive.bats](../../../../../tests/sys/softeng.sh-action-uarchive.bats)
  - mixed file (per-test classification): 5 tests using `_make_change_folder` call `_setup_git_origin` (uarchive resolves WCFs against `origin/<default-branch>`); the "error cases: unknown flag + mutually exclusive options" test (line 140) uses the cheap default

- [x] update: [tests/sys/softeng.sh-action-usync.bats](../../../../../tests/sys/softeng.sh-action-usync.bats)
  - mixed file (per-test classification): 12 git-using tests call `_setup_git_origin` (usync fetches `origin/<default-branch>`); the "no git repo" test at line 185 uses the cheap default
  - remove now-redundant `rm -rf "$PROJECT_ROOT/.git"` at the same test

- [x] update: [tests/sys/softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - mixed file (per-test classification): the 26 tests that push / read upstream call `_setup_git_origin`; the "no git repository" test uses the cheap default. Cannot use a file-level override because it would conflict with the "no git" test
  - remove now-redundant `rm -rf "$PROJECT_ROOT/.git"` at the same test

- [x] update: [tests/sys/softeng.sh-action-umergepr.bats](../../../../../tests/sys/softeng.sh-action-umergepr.bats)
  - mixed file (per-test classification): the 12 git-using tests call `_setup_git_origin`; the "no git repository" test uses the cheap default
  - remove now-redundant `rm -rf "$PROJECT_ROOT/.git"` at the same test

- [x] update: [tests/sys/softeng.sh-diff.bats](../../../../../tests/sys/softeng.sh-diff.bats)
  - file-level `setup()` override calling `_setup_git_origin` (`uspecs diff` resolves against `origin/<default-branch>`)

- [x] update: [tests/sys/softeng.sh-wcf-list.bats](../../../../../tests/sys/softeng.sh-wcf-list.bats)
  - mixed file (per-test classification): "no git repo" test uses the cheap default; "git repo" test calls `_setup_git_origin` (uses `git push -q origin main` to seed the upstream side of the WCF detection)
  - remove now-redundant `rm -rf "$PROJECT_ROOT/.git"` at the "no git repo" test

- [x] update: [tests/sys/softeng.sh-self-review.bats](../../../../../tests/sys/softeng.sh-self-review.bats)
  - keep the existing file-level `setup()` override as-is: it deliberately points `PROJECT_ROOT` at `$REPO_ROOT` (real repo) rather than a temp dir, so it does not fit `_setup_project_root`; refresh the explanatory comment to reflect the new layered helpers

- [x] run: `tests/run-tests.py sys` - 119 / 120 sys tests pass (the single remaining `uimpl: specs-side todos do NOT include concurrency-evaluation instruction` failure also fails on the baseline commit `ab28c180` and is unrelated to this refactor)

## Results

- 120 tests, 0 failures, 99.0s
