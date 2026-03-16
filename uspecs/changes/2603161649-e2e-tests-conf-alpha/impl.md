# Implementation plan: E2E tests for conf install alpha scenarios

## Construction

- [x] update: [tests/e2e/conf-install.bats](../../../tests/e2e/conf-install.bats)
  - add: "Alpha install (local, nlic)" test - installs with --nlic, asserts CLAUDE.md created and metadata contains nlic
  - add: "Alpha install (local, nlia + nlic)" test - installs with both methods, asserts both AGENTS.md and CLAUDE.md created
