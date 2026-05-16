---
registered_at: 2026-05-16T14:07:25Z
change_id: 2605161407-add-uclarify-to-plugins
baseline: 51df833a1ca61cfe4c0facd910e45627b6a1e1b6
archived_at: 2026-05-16T15:42:19Z
---

# Change request: Include uclarify as a plugin command

## Why

`uclarify` currently exists only as a local Claude skill at `.claude/skills/uclarify/SKILL.md` and is not registered as a softeng action. As a result it is not delivered to the generated `uspecs-plugins-claude` or `uspecs-plugins-augment` plugins, so plugin users cannot invoke it the way they invoke `upr`, `uchange`, `uimpl`, `uversion`, etc.

## What

Register `uclarify` as a first-class softeng action so it ships in the generated Claude and Augment plugins alongside the other commands.

- This is the only action so far that is not processed calling softeng.sh

## How

Decisions:

- `uclarify` does not dispatch through `softeng.sh`; the action template body is rendered directly into the plugin command/skill (no `cmd_action_uclarify`, no entry in the action case, no `bin/prompts/instr_uclarify.md`)

- `git mv .claude/skills/uclarify/SKILL.md scripts/templates/actions/uclarify.md` (preserves history); then reshape the file in place from skill front-matter format into the command body format consumed by `render_action_file`. The AGENTS.md / CLAUDE.md carve-out below provides the source-repo trigger path in place of Claude's skill discovery

- Create `uspecs/specs/prod/softeng/uclarify.feature` with minimal conventional content: `Feature: <title>`, a one-line description, and one happy-path `Scenario` per mode (Interactive and Auto); this resolves `read_feature_description` like every other action and keeps the "every action has scenarios" convention

- Extend the action YAML schema with an optional `file` field, mutually exclusive with `raw_text`; when present, `load_actions` reads the action body from that file

- Add `scripts/templates/actions/uclarify.yaml` with `file: uclarify.md` so the marketplace generator surfaces `uclarify` in both Claude (`commands`) and Augment (`skills`) outputs

- In the `<!-- uspecs:begin -->` block of `AGENTS.md` and `CLAUDE.md`, add a separate top-level rule above the existing dispatch rule: when user input starts with `uclarify [options] {other-input}`, read `scripts/templates/actions/uclarify.md` and follow its instructions, treating `{other-input}` as the clarification input. `uclarify` is intentionally not added to the "Available commands" list, which enumerates only `softeng.sh`-dispatched actions

Out of scope:

- Changing the clarification semantics (modes, decision recording format, option/review prompt structure); the existing skill behavior is reused as-is

References:

- [bin/softeng.sh](../../../../../bin/softeng.sh)
- [scripts/templates/actions/uversion.yaml](../../../../../scripts/templates/actions/uversion.yaml)
- [.claude/skills/uclarify/SKILL.md](../../../../../.claude/skills/uclarify/SKILL.md)
- [scripts/_lib/gen-uspecs-market.py](../../../../../scripts/_lib/gen-uspecs-market.py)
- [AGENTS.md](../../../../../AGENTS.md)
- [CLAUDE.md](../../../../../CLAUDE.md)

## Functional design

- [x] create: [softeng/uclarify.feature](../../../../specs/prod/softeng/uclarify.feature)
  - Feature Specification for the uclarify action: `Feature:` title, a one-line description, and one happy-path `Scenario` per mode (Interactive and Auto)

## Technical design

- [x] update: [softeng/arch.md](../../../../specs/prod/softeng/arch.md)
  - update: Overview to note that `uclarify` is the exception to the uniform `softeng.sh` dispatch pattern; the AI Agent reads the action body directly
  - add: `uclarify` entry in the actions list with dispatch "read `scripts/templates/actions/uclarify.md` and follow it (no `softeng.sh`)", input "specification or artifact file (implicit from context)", output "decision integrated into the file; entry appended to `decisions.md` when the target is in a Change Folder"

## Construction

- [x] update: [actions/uclarify.md](../../../../../scripts/templates/actions/uclarify.md)
  - move: `git mv .claude/skills/uclarify/SKILL.md scripts/templates/actions/uclarify.md` to preserve history
  - update: strip the skill YAML frontmatter (`name`, `description`, `disable-model-invocation`); the body becomes the action template consumed by `render_action_file` via the new `file:` field
  - update: leading `# Clarifications` heading kept; subsequent section structure (`Modes`, `On invocation`, `Input`, `Decision recording`, `Interactive mode`, `Auto mode`) unchanged

- [x] create: [actions/uclarify.yaml](../../../../../scripts/templates/actions/uclarify.yaml)
  - Action manifest for the marketplace generator
  - Fields: `action: uclarify`, `file: uclarify.md` (mutually exclusive with `raw_text`)
  - No `options` field

- [x] update: [_lib/gen-uspecs-market.py](../../../../../scripts/_lib/gen-uspecs-market.py)
  - update: `load_actions` to accept either `raw_text` or `file` in the action YAML; when `file` is set, read the body from `ACTIONS_DIR / data["file"]`; error if both or neither are present
  - update: `render_action_file` so the rendered body is used as-is when sourced from `file` (no `{{dispatch}}` substitution required); `{{description}}`, `{{action}}`, `{{options_line}}` substitution still applies if the placeholders are present

- [x] update: [AGENTS.md](../../../../../AGENTS.md)
  - update: inside the `<!-- uspecs:begin -->` block, add a separate top-level rule above the existing dispatch rule: when user input starts with `uclarify [options] {other-input}`, read `scripts/templates/actions/uclarify.md` and follow its instructions, treating `{other-input}` as the clarification input
  - update: leave `uclarify` out of the "Available commands" list under the existing rule

- [x] update: [CLAUDE.md](../../../../../CLAUDE.md)
  - update: mirror the AGENTS.md change in the `<!-- uspecs:begin -->` block

- [x] update: [e2e/deliver.bats](../../../../../tests/e2e/deliver.bats)
  - add: `uclarify` presence assertions in the three dev-path scenarios (claude, augment, codex), mirroring the existing `uarchive` pattern: file exists at the expected path and the rendered body contains `# Clarifications` (proves the `file:` field was honoured and the frontmatter was stripped)
  - claude scenario: assert `commands/uclarify.md` exists and body contains `# Clarifications`
  - augment/codex scenarios: assert `skills/uclarify/SKILL.md` exists, frontmatter contains `name: uclarify`, body contains `# Clarifications`

- [x] update: [action-skill-generic.md](../../../../../scripts/templates/action-skill-generic.md)
  - update: add `disable-model-invocation: true` to the frontmatter so all generated Augment/Codex action skills opt out of autonomous model invocation; actions are user-driven by design
  - update: extend the augment/codex dev-path assertions in `tests/e2e/deliver.bats` to confirm the new frontmatter line is present on at least one generated action skill (e.g. `uarchive`)

## Quick start

In an installed plugin, invoke `uclarify` like any other action:

- Claude Code: `/uclarify` (with optional `--auto` and an implicit or explicit target file)
- Augment Code / Codex: `uclarify` (skill-invoked)

In the source repo, the agent recognises `uclarify [options] {other-input}` at the start of user input and reads `scripts/templates/actions/uclarify.md` directly; no `softeng.sh` dispatch occurs.
