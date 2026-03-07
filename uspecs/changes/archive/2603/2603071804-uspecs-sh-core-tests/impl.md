# Implementation plan: Core tests for uspecs.sh

## Functional design

- [x] create: [dev/uspecs-sh-tests.feature](../../../../specs/devops/dev/uspecs-sh-tests.feature)
  - add: Scenario "Developer runs system tests"
  - add: Scenario "Developer runs e2e tests"

## Technical design

- [x] create: [dev/uspecs-sh-tests--td.md](../../../../specs/devops/dev/uspecs-sh-tests--td.md)
  - add: Test levels (system vs e2e) with definitions and scope
  - add: Test framework and file layout
  - add: System test setup (temp project root, local bare repos, gh stub)
  - add: Developer commands to run each level
  - add: Scenario implementation section (how each scenario is implemented)

## Construction

- [x] create: [.gitignore](../../../../../.gitignore)
  - add: ignore hidden directories (`.*/`)

- [x] create: [tests/stubs/gh](../../../../../tests/stubs/gh)
  - add: bash stub script that records args to gh.calls and stdin to gh.body, prints a fake PR URL and exits 0

- [x] create: [tests/helpers.bash](../../../../../tests/helpers.bash)
  - add: setup/teardown helpers (temp project root, local bare repo as origin, gh stub on PATH)
  - add: Windows path fix -- convert BATS_TEST_TMPDIR via cygpath -m on MSYS/Cygwin
  - add: `uspecs` helper that runs uspecs.sh merging stderr into stdout
  - add: `_make_change_folder` helper to create a minimal committed change folder

- [x] create: [tests/uspecs.sh.bats](../../../../../tests/uspecs.sh.bats)
  - add: load 'helpers' to share setup/teardown
  - test: unknown command fails with usage error

- [x] create: [tests/uspecs.sh-change-new.bats](../../../../../tests/uspecs.sh-change-new.bats)
  - test: `change new` creates change folder and change.md
  - test: `change new --branch` creates git branch
  - test: `change new` with unknown flag fails
  - test: `change new` with missing change-name fails
  - test: `change new` with invalid change-name format fails

- [x] create: [tests/uspecs.sh-change-archive.bats](../../../../../tests/uspecs.sh-change-archive.bats)
  - test: `change archive` moves change folder to archive/
  - test: `change archive` with uncompleted items fails
  - test: `change archive` when change.md missing fails
  - test: `change archive -d` squashes, pushes, deletes branch

- [x] create: [tests/uspecs.sh-pr-preflight.bats](../../../../../tests/uspecs.sh-pr-preflight.bats)
  - test: `pr preflight` succeeds on valid change branch

- [x] create: [tests/uspecs.sh-pr-create.bats](../../../../../tests/uspecs.sh-pr-create.bats)
  - test: `pr create` succeeds and outputs PR URL
  - test: `pr create` passes correct args to gh and correct body via stdin

- [x] create: [tests/uspecs.sh-diff.bats](../../../../../tests/uspecs.sh-diff.bats)
  - test: `diff specs` outputs diff between HEAD and default branch

- [x] create: [tests/e2e/uspecs.sh-e2e.bats](../../../../../tests/e2e/uspecs.sh-e2e.bats)
  - add: placeholder file with header comment (no test cases yet)
