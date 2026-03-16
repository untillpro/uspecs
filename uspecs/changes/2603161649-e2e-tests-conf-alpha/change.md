---
registered_at: 2026-03-16T16:49:10Z
change_id: 2603161649-e2e-tests-conf-alpha
baseline: 379b7a843f880ac62e546b851a42d43dffe36ec0
---

# Change request: E2E tests for conf install alpha scenarios

## Why

The existing e2e test file `tests/e2e/conf-install.bats` only covers alpha install with nlia method. Several install scenarios from the spec are untested - nlic method, both methods combined, and the no-git-repo failure case.

## What

Add e2e tests for alpha install scenarios to `tests/e2e/conf-install.bats`:

- Alpha install with nlic method (local) - verifies CLAUDE.md is created
- Alpha install with both nlia and nlic methods (local) - verifies both AGENTS.md and CLAUDE.md
- No git repository failure - verifies error when running install outside a git repo
