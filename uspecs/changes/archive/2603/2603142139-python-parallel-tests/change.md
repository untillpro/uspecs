---
registered_at: 2026-03-14T20:28:03Z
change_id: 2603142028-python-parallel-tests
baseline: 6d5fddfe0d26fb9c60df90cd3d115025edbb0024
archived_at: 2026-03-14T21:39:06Z
---

# Change request: Python parallel test runner

## Why

The current test infrastructure uses bats for bash testing, but there is a need for a more flexible test execution system that can extract tests based on patterns and run them in parallel to improve test execution speed and developer productivity.

## What

Python-based test runner that discovers and executes individual bats tests in parallel:

- Test discovery by recursively scanning a specified folder for .bats files
- Parses `@test` definitions from .bats files to run individual tests via `bats -f`
- Optional filter parameter to match test names (e.g., "shell metacharacters" matches `@test "handles unsafe values with shell metacharacters"`)
- Parallel test execution to reduce overall test time
  - Parallelism defined via `--workers N` parameter
  - Default: auto-detect CPU cores using `os.cpu_count()`
  - `--workers 1` for sequential execution (debugging)
  - Uses ProcessPoolExecutor with as_completed for streaming results
- Results reported as each test completes, with relative file path and test name
- Summary with total tests, failures, and elapsed time
- Shows stdout+stderr for failed tests
- Windows compatibility: shell=True and forward-slash path conversion
