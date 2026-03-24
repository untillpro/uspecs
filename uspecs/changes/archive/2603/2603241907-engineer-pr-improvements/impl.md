# Implementation plan: Engineer PR Improvements

## Functional design

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: WCF is not archived when Engineer creates a PR
  - update: PR body is taken from change.md
  - update: commit message references change.md without path

## Construction

- [x] update: [scripts/uspecs.sh](../../../../../uspecs/u/scripts/uspecs.sh)
  - remove: WCF archival block from cmd_action_upr
  - update: pr_body to be read from change.md content with frontmatter --- replaced by yaml code block
  - add: pr_body truncation to 4000 chars with notice when exceeded (--web uses URL query params)
  - update: see_details_line to use "change.md" without path
  - update: temp_create_file callers to use nameref pattern
- [x] update: [stubs/gh](../../../../../tests/sys/stubs/gh)
  - update: --body-file handling to read from file path argument instead of stdin
- [x] update: [uspecs.sh-prompt-upr.bats](../../../../../tests/sys/uspecs.sh-prompt-upr.bats)
  - update: "WCF is active" test to assert WCF remains active (not archived)
  - update: commit message tests to expect "See change.md for details" without path
  - add: pr_body assertions to verify change.md content is passed via --body-file
  - add: truncation test for large change.md exceeding 4000 chars
- [x] update: [utils.sh](../../../../../uspecs/u/scripts/_lib/utils.sh)
  - add: source guard to prevent multiple executions of side-effect code
  - add: atexit trap chaining -- capture pre-existing EXIT trap and restore it as first atexit handler
  - remove: _TEMP_DIRS, _TEMP_FILES arrays and temp_cleanup function
  - update: temp_create_file and temp_create_dir to register cleanup directly via atexit_add
  - update: temp_create_file and temp_create_dir to use nameref parameter instead of stdout (avoids subshell scope loss)
- [x] update: [conf.sh](../../../../../uspecs/u/scripts/conf.sh)
  - update: all 6 temp_create_file/temp_create_dir callers to use nameref pattern
- [x] add: [utils-atexit.bats](../../../../../tests/unit/utils-atexit.bats)
  - add: unit tests for atexit_add, atexit_push, atexit_pop, trap chaining, source guard
  - add: unit tests for temp_create_file and temp_create_dir cleanup
- [x] update: [run-tests.py](../../../../../tests/run-tests.py)
  - fix: stdin closed via subprocess.DEVNULL to prevent hangs
  - fix: stdout flushed immediately for real-time output
