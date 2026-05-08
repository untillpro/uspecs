---
registered_at: 2026-05-08T14:00:47Z
change_id: 2605081400-uchange-idempotent-window
baseline: 03446b3e0fecfd203d1b72d76575ac1be61ee31e
---

# Change request: Move uchange filesystem side effects to the agent

## Why

When an agent invokes `uchange` and never receives the response (timeout, disconnect, retry), the bash script has already mutated the filesystem: a Change Folder with a `change.md` is created, and a git branch is checked out. The agent then retries, producing duplicate Change Folders (different timestamp prefix, same kebab-name) and sometimes branch creation failures. The root cause is that `uchange` performs side effects before the agent has confirmed receipt of the action's output.

## What

Make `cmd_action_uchange` side-effect-free with respect to the Change Folder and `change.md`: bash only ensures the parent `uspecs/changes/` directory exists and emits instructions; the agent creates the Change Folder, writes `change.md`, and creates the git branch.

Introductory items:

- `uspecs/changes/` is the only path bash creates; the timestamped Change Folder is not created by bash
- The frontmatter (`registered_at`, `change_id`, `baseline`, optional `issue_url`) is computed by bash and emitted as a verbatim artifact in `AGENT_INSTRUCTIONS`
- The agent receives a single instruction to create `uspecs/changes/<timestamp>-<kebab-name>/`, write `change.md` with the supplied frontmatter, and append the Why/What (and How if `!--no-impl`) sections
- Branch creation moves into the agent instructions: when applicable, the agent runs `git checkout -b <branch>` itself
- A lost response no longer leaves stale folders or branches behind; a retried `uchange` simply emits a fresh set of instructions

## How

- Shrink `cmd_change_new` (or fold its remainder into `cmd_action_uchange`) so it only validates the kebab-name, ensures `uspecs/changes/` exists, computes `timestamp`, `folder_name`, `change_folder_rel`, and the frontmatter block; remove `mkdir` for the Change Folder, remove the `change.md` write, remove the `git checkout -b` call
- Emit the computed YAML frontmatter as an opaque artifact via `emit_artifact "change_frontmatter" "$frontmatter" "..."` so it appears as `<artifact id="change_frontmatter" ...>` in `AGENT_INSTRUCTIONS`; the agent copies that block verbatim to the top of `change.md`
- Update `instr_uchange.md` so the instruction is "create `${change_file}` with the contents of `@artifact_change_frontmatter`, then append Why/What (and How if applicable)" instead of "append to `${change_file}`"
- When `--branch` semantics apply, pass `branch_name` and a "create branch" directive into the agent instruction; remove the `git checkout -b` invocation from bash
- Rewrite the bats cases in `tests/sys/softeng.sh-action-uchange.bats` to assert on `AGENT_INSTRUCTIONS` content (folder name pattern, frontmatter fields, branch directive presence/absence, `issue_url` propagation) rather than on post-action filesystem state; the existing "changes folder auto-creation" case stays as is since `uspecs/changes/` is still created by bash
- Update `bin/prompts/instr_uchange.md` and any referenced artdefs to reflect the create-from-scratch flow

References:

- [bin/softeng.sh](../../../bin/softeng.sh)
- [bin/prompts/instr_uchange.md](../../../bin/prompts/instr_uchange.md)
- [tests/sys/softeng.sh-action-uchange.bats](../../../tests/sys/softeng.sh-action-uchange.bats)

## Construction

- [x] update: [tests/sys/softeng.sh-action-uchange.bats](../../../tests/sys/softeng.sh-action-uchange.bats)
  - update: existing scenarios to assert on `AGENT_INSTRUCTIONS` content instead of post-action filesystem state (no `[ -f .../change.md ]`, no `[ -d .../<timestamp>-<name> ]`, no branch existence checks)
  - add: assertion that `<artifact id="change_frontmatter" ...>` appears in output and contains `change_id:`, `registered_at:`, `baseline:`, and (when `--issue-url` provided) `issue_url:`
  - add: assertion that the instruction body references the timestamped Change Folder path matching `uspecs/changes/<10-digit-ts>-<kebab-name>/`
  - update: branch-related scenarios (`--branch`, `--no-branch`, default-branch, non-default-branch, issue-URL branch naming) to assert presence/absence and content of the agent-side branch directive in the instruction body
  - keep: the "changes folder auto-creation" case asserting that `uspecs/changes/` is created by bash; remove the `change.md` existence check
  - keep: error-path cases (`--kebab-name is required`, mutually exclusive flags, invalid kebab format, unknown flag) unchanged

- [x] update: [bin/softeng.sh](../../../bin/softeng.sh)
  - update: `cmd_change_new` -> remove `mkdir -p "$change_folder"`, remove the `printf '%s\n' "$frontmatter" > "$change_folder/change.md"` write, remove the `git checkout -b` block; keep kebab validation, `uspecs/changes/` `mkdir -p`, timestamp + folder name computation, frontmatter assembly
  - update: `cmd_change_new` return contract -> output both `change_folder_rel` and the assembled frontmatter to its caller (e.g. via two named-ref out-params, or fold the remaining logic directly into `cmd_action_uchange`)
  - update: `cmd_action_uchange` -> after obtaining the frontmatter, call `emit_artifact "change_frontmatter" "$frontmatter" "Frontmatter for change.md (copy verbatim)"` before `emit_prompt`
  - add: `change_folder` and (when applicable) `branch_name` / `create_branch` entries in the `context_vars` map passed to `emit_prompt`
  - keep: `--branch` / `--no-branch` precedence rules and `extract_issue_id` use; the resolved `branch_name` and `create_branch` flag are now passed to the agent rather than acted on directly

- [x] update: [bin/prompts/instr_uchange.md](../../../bin/prompts/instr_uchange.md)
  - update: instruction body so the agent first creates folder `${change_folder}`, then creates `${change_file}` containing the verbatim contents of `@artifact_change_frontmatter`, then appends the Why/What (and How if `!no_impl`) sections
  - add: conditional line `Run \`git checkout -b ${branch_name}\` (?create_branch)` so branch creation appears only when bash signals it
  - keep: the existing `@artdef_change_why_what`, `@artdef_change_how`, and `@include_impl_sections` references and ordering
