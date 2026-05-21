---
registered_at: 2026-05-21T21:01:19Z
change_id: 2605212101-softeng-detect-skill-plugin-cwd
type: feat
scope: softeng
baseline: 4c9b70ff8b8592a62336e7a9b3aa98a58b47911a
issue_url: https://github.com/untillpro/uspecs/issues/102
archived_at: 2026-05-21T22:06:48Z
---

# Change request: Detect skill/plugin root as cwd in softeng

Refs:

- [102: softeng.sh: detect skill/plugin root as cwd and fail with a clear message](./issue-102.md)

## Why

Invoking the softeng entry point from a directory whose root is a uspecs skill or plugin (rather than a uspecs-using project) currently proceeds and can produce confusing behaviour or misleading errors. A guard that fails fast with a clear, actionable message prevents this misuse and protects skill/plugin source trees from being treated as project working copies.

## How

Decisions:

- Add an early cwd guard in [`bin/softeng.sh`](../../../../../bin/softeng.sh) at the top of `main`, before any subcommand dispatch
- Apply the guard uniformly to every invocation, including read-only commands such as `action uversion` and `meta options` — no per-command carve-outs
- Detect a skill root by the presence of `SKILL.md` in cwd
- Detect a plugin root by the presence of `.claude-plugin/plugin.json` (plugin folder) or `.claude-plugin/marketplace.json` (marketplace repo root) in cwd
- If any of the above markers is present, abort with a descriptive message and a non-zero exit code
- Keep the regular uspecs-using project path unaffected (no marker means no change in behaviour)
- Cover the new guard with tests under `tests/` using the project's existing test runner

Out of scope:

- Detecting nested invocations from arbitrary subdirectories of a skill or plugin (only the root is in scope)
- Auto-correcting the cwd or suggesting an alternative directory beyond the error message

References:

- [softeng entry point](../../../../../bin/softeng.sh)
- [test runner](../../../../../tests/run-tests.py)

## Functional design

- [x] create: [softeng/shared/cwd-validations.feature](../../../../specs/prod/softeng/shared/cwd-validations.feature)
  - Shared Feature Specification: cwd validations applied uniformly to every softeng.sh invocation (including non-action subcommands such as `meta options` and `self-review`); Scenario Outline with one example row per detected marker — skill root (`SKILL.md`), plugin folder (`.claude-plugin/plugin.json`), marketplace repo root (`.claude-plugin/marketplace.json`) — each causing the script to exit with error informing AI Agent that it is being run from a uspecs plugin or skill directory and that the uspecs-using project root must be used as cwd; limited to the script's own behaviour (AI Agent's reaction to script errors is already covered by `shared/script-execution.feature`)

## Construction

- [x] create: [sys/softeng.sh-cwd-guard.bats](../../../../../tests/sys/softeng.sh-cwd-guard.bats)
  - System tests for the new cwd guard in `bin/softeng.sh`
  - Cases: cwd is a skill root (cwd contains `SKILL.md`), cwd is a plugin folder (cwd contains `.claude-plugin/plugin.json`), cwd is a marketplace repo root (cwd contains `.claude-plugin/marketplace.json`) — each must cause the script to exit with non-zero status and emit an error message indicating the script is being run from a uspecs plugin or skill directory and that the uspecs-using project root must be used as cwd
  - Case: cwd has no markers — script proceeds normally (any unrelated subcommand exits as it would today)
  - Guard fires uniformly across subcommand families, so cover at least one `action`, one `meta`, and one top-level path (e.g. `self-review`) per marker — keep the matrix compact (Bats parameterisation or shared helper)

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - add: early cwd guard at the top of `main()` (before the `git_path` call and any subcommand dispatch) that checks for `SKILL.md`, `.claude-plugin/plugin.json`, and `.claude-plugin/marketplace.json` in cwd
  - add: error message indicates the script is being run from a uspecs plugin or skill directory and instructs the caller to set cwd to the root of the uspecs-using project
  - exit with non-zero status when the guard fires; otherwise behaviour is unchanged

- [x] update: [_lib/gen-uspecs-market.py](../../../../../scripts/_lib/gen-uspecs-market.py)
  - update: `_DISPATCH_PLUGIN_ROOT`, `_DISPATCH_REL_BIN`, and the Claude `dispatch=` literal in `AGENT_CONFIGS` to include the instruction "set cwd to the root of the uspecs-using project before running"; wording shared across all three so generated action skills/commands carry the same cwd contract

- [x] update: [AGENTS.md](../../../../../AGENTS.md)
  - update: inside the `<!-- uspecs:begin -->` … `<!-- uspecs:end -->` execution-instructions block, add the "set cwd to the project root before running `bin/softeng.sh`" contract; applies to both the `uchange` dispatch line and the generic `{action}` dispatch line

- [x] update: [CLAUDE.md](../../../../../CLAUDE.md)
  - update: same edit as in `AGENTS.md`, inside the `<!-- uspecs:begin -->` … `<!-- uspecs:end -->` execution-instructions block
