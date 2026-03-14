# Implementation plan: Python parallel test runner

## Functional design

- [x] update: [dev/tests.feature](../../specs/devops/dev/tests.feature)
  - add: Scenario "Developer runs tests in parallel using Python runner with pattern"
  - add: streaming results and elapsed time in Then clauses

## Provisioning and configuration

- [x] verify: Python 3.8+ is installed

## Construction

- [x] create: [scripts/run-tests.py](../../../scripts/run-tests.py)
  - add: CLI argument parsing (folder, optional pattern, --workers flag)
  - add: Recursive .bats file discovery via pathlib.rglob
  - add: @test name extraction and per-test execution via `bats -f`
  - add: Pattern matching against @test names (substring match)
  - add: Parallel execution using ProcessPoolExecutor with as_completed
  - add: Streaming result output as each test completes
  - add: Relative file path and test name in each result line
  - add: Summary with total tests, failures, elapsed time
  - add: stdout+stderr output for failed tests
  - add: Windows compatibility (shell=True, forward-slash path conversion)
