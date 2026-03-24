# Implementation plan: atexit trap API in utils.sh

## Construction

- [x] update: [u/scripts/_lib/utils.sh](../../../../u/scripts/_lib/utils.sh)
  - add: `_ATEXIT_CMDS` global array - accumulates EXIT handler commands
  - add: `_ATEXIT_STACK` global array - stack for push/pop
  - add: `_atexit_run` internal dispatcher function - captures `rc=$?` first, runs `_ATEXIT_CMDS` then walks `_ATEXIT_STACK` (all entries with `|| true` so cleanups never mask the original exit code), ends with `exit "$rc"`
  - add: `trap _atexit_run EXIT` at module level when utils.sh is sourced
  - add: `atexit_add <cmd>` - appends cmd to `_ATEXIT_CMDS`
  - add: `atexit_push <cmd>` - pushes cmd onto `_ATEXIT_STACK`
  - add: `atexit_pop` - removes last entry from `_ATEXIT_STACK`

- [x] update: [u/scripts/conf.sh](../../../../u/scripts/conf.sh)
  - add: source `utils.sh` (alongside existing `git.sh` source)
  - remove: `_TEMP_DIRS` and `_TEMP_FILES` global arrays
  - remove: `cleanup_temp` function
  - remove: bare `trap cleanup_temp EXIT`
  - update: `create_temp_dir` - register `rm -rf "$temp_dir"` via `atexit_add` on each call instead of accumulating in array
  - update: `create_temp_file` - register `rm -f "$temp_file"` via `atexit_add` on each call instead of accumulating in array

- [x] create: [tests/unit/utils-atexit.bats](../../../../../tests/unit/utils-atexit.bats)
  - add: test `atexit_add` - single handler runs on exit
  - add: test `atexit_add` multiple - all handlers run in registration order
  - add: test `atexit_push` / `atexit_pop` - pushed cmd runs on exit; popped cmd does not
  - add: test `atexit_pop` on empty stack - no error
  - add: test exit code preserved - original non-zero rc propagates through dispatcher

- [x] update: [tests/run-tests.py](../../../../../tests/run-tests.py)
  - fix: terminal output corruption from interleaved writes during parallel execution
  - add: `sys.stdout.reconfigure(write_through=True)` in `main()` to bypass Python's internal buffer
  - update: `subprocess.run` in `run_bats_test` to use explicit `stdin=DEVNULL, stdout=PIPE, stderr=PIPE` instead of `capture_output=True`
  - add: `flush=True` to all `print()` calls in the results loop and summary
