# Implementation plan: Install override mode

## Functional design

- [x] update: [conf/install.feature](../../../../specs/prod/conf/install.feature)
  - add: Scenario for install with --override flag that succeeds even when uspecs is already installed
  - update: Edge cases table - clarify that "uspecs is already installed" failure does not apply when --override is used

## Construction

- [x] update: [u/scripts/conf.sh](../../../../u/scripts/conf.sh)
  - update: cmd_install - add --override flag parsing, skip check_not_installed when override is true, pass --override through apply_args
  - update: cmd_apply - add --override flag parsing, skip "already installed" checks (lines 596-598 and 610-612) when override is true
- [x] update: [tests/e2e/conf-install.bats](../../../../../tests/e2e/conf-install.bats)
  - add: Test that install with --override succeeds when uspecs is already installed
