---
name: softeng-action-options
description: Use this skill when authoring or reviewing edits to `ACTION_OPTIONS` in `bin/softeng.sh` or to `cmd_action_*` argument parser case arms.
user-invocable: false
---

Action option metadata and parser arms must stay aligned.

When editing `bin/softeng.sh`:

- If you change an entry in `ACTION_OPTIONS`, check the corresponding `cmd_action_<action>` parser accepts the same flags.
- If you change a `cmd_action_*` parser `case "$1" in` arm, check the corresponding `ACTION_OPTIONS` entry documents the same flags.
- Keep the rendered option text suitable for generated command and skill files: `softeng meta options <action>` prints it as `Options: ...`.

Local consistency check: `tests/sys/softeng.sh-meta-options.bats`

```bash
python3 tests/run-tests.py tests/sys softeng.sh-meta-options
```
