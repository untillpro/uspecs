---
registered_at: 2026-03-12T11:59:53Z
change_id: 2603121159-pr-body-via-parameter
baseline: c9614d33d1f10184c96e64781e1fe3b439938e6f
---

# Change request: Pass PR body via --body parameter instead of stdin

## Why

Agent uses PowerShell to execute shell commands. Piping `pr_body` via stdin from PowerShell to bash is unreliable - the Agent emits the body to stdout, making the stdin pipe meaningless. The script already supports `--body` as a CLI parameter.

## What

Update upr action to pass `pr_body` via `--body` parameter:

- Change `actn-upr.md` instruction from stdin piping to `--body "{pr_body}"` CLI parameter
- Add note about escaping shell-special characters in `pr_body` (same as `pr_title`)