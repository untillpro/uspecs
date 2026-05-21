# softeng.sh: detect skill/plugin root as cwd and fail with a clear message

- URL: https://github.com/untillpro/uspecs/issues/102
- ID: #102
- State: open
- Author: @maxim-ge (Maxim Geraskin)
- Labels: none

## Problem

When `bin/softeng.sh` is invoked from a directory whose root is a uspecs skill or plugin (instead of a uspecs-using project), the command currently proceeds and can produce confusing behaviour or misleading errors.

## Proposal

Add a cwd check at the start of `bin/softeng.sh`:

- Detect whether the current working directory is the root of a skill or a plugin.
- If so, abort early with a clear, actionable error message explaining that `softeng.sh` must be run from a uspecs-using project (not from inside a skill/plugin source tree).

## Acceptance criteria

- Running `bin/softeng.sh` from a skill root fails with a descriptive message and a non-zero exit code.
- Running `bin/softeng.sh` from a plugin root fails with a descriptive message and a non-zero exit code.
- Running from a regular uspecs-using project is unaffected.
- Behaviour is covered by tests.

---
Co-authored by [Augment Code](https://www.augmentcode.com/?utm_source=github&utm_medium=github_issue&utm_campaign=github)
