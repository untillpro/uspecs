---
registered_at: 2026-03-23T19:56:41Z
change_id: 2603231956-utils-atexit-trap-api
baseline: 0a34e1df87fb79757900d48b2db4c667c81f4a79
archived_at: 2026-03-24T17:16:51Z
---

# Change request: atexit trap API in utils.sh

## Why

Scripts and tests independently register EXIT handlers with `trap ... EXIT`, which silently overwrites any previously registered handler. A shared accumulating API in `utils.sh` would let any sourced script safely add its own cleanup without stomping others.

## What

Add `atexit_add`, `atexit_push`, and `atexit_pop` to `utils.sh`:

- `atexit_add <cmd>` - accumulate an EXIT handler; uses an internal array + single dispatcher so handlers never overwrite each other
- `atexit_push <cmd>` - push a command onto a separate LIFO stack; the dispatcher runs stack entries after `_ATEXIT_CMDS` on exit
- `atexit_pop` - remove the last-pushed command from the stack (undo a push)

Migrate existing temp-file cleanup in `conf.sh` to use the new API:

- remove `cleanup_temp`, `_TEMP_DIRS`, and `_TEMP_FILES`; register each temp resource directly via `atexit_add` at creation time
- source `utils.sh` in `conf.sh` so the functions are available
