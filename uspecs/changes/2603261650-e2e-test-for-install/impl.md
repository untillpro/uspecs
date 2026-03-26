# Implementation plan: E2E test for install

## Functional design

- [x] update: [conf/install.feature](../../specs/prod/conf/install.feature)
  - add: Curl-pipe install rule and scenario
- [x] update: [conf/arch.md](../../specs/prod/conf/arch.md)
  - add: Curl-pipe install flow (two-phase execution)

## Construction

- [x] update: [e2e/conf-install.bats](../../../tests/e2e/conf-install.bats)
  - add: "Alpha install (remote, nlia)" - install with --alpha --nlia, verify uspecs.yml has alpha version with commit field, AGENTS.md created
- [x] update: [u/scripts/conf.sh](../../u/scripts/conf.sh)
  - fix: skip sourcing _lib/git.sh when BASH_SOURCE[0] is not a file (curl-pipe case)
  - fix: make cmd_install self-contained for pipe case (mktemp + trap for temp dir, inline error handling)
- [x] update: [e2e/conf-install.bats](../../../tests/e2e/conf-install.bats)
  - add: "Alpha install (curl pipe)" - install via curl pipe, verify uspecs.yml has alpha version with commit field, AGENTS.md created
- [x] update: [run-tests.py](../../../tests/run-tests.py)
  - add: IS_WINDOWS helper constant, cap workers at 10 on Windows
