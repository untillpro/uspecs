---
registered_at: 2026-03-12T11:59:53Z
change_id: 2603121159-pr-body-via-parameter
baseline: c9614d33d1f10184c96e64781e1fe3b439938e6f
archived_at: 2026-03-12T12:27:21Z
---

# Change request: Pass PR body via --body parameter instead of stdin

## Why

Agent uses PowerShell to execute shell commands. Piping `pr_body` via stdin from PowerShell to bash is unreliable - the Agent emits the body to stdout, making the stdin pipe meaningless. The script already supports `--body` as a CLI parameter.

## What

Update upr action and scripts to pass `pr_body` via `--body` parameter with `\n` encoding:

- Change `actn-upr.md` instruction from stdin piping to `--body "{pr_body}"` CLI parameter with newline encoding as literal `\n` sequences
- Add `\n` decoding in `pr.sh` for both `cmd_changepr` and `cmd_pr`
- Add shell-special characters note for `pr_title` and `pr_body`
- Add test for `\n` decoding in PR body
