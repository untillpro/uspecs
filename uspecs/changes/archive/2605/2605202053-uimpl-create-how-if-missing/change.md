---
registered_at: 2026-05-18T06:57:07Z
change_id: 2605180657-uimpl-create-how-if-missing
type: feat
scope: softeng
baseline: fe84421e01ad83092d51f24689425bce80b50f06
archived_at: 2026-05-20T20:53:23Z
---

# Change request: uimpl creates the How section when missing

## Why

The `## How` section captures the implementation approach for a change. Today the section only appears when `uchange --how` was used at creation time, so change folders started without `--how` have no built-in path to add it later and engineers must insert the section manually. Letting `uimpl` create the section on demand removes that friction and keeps the implementation plan complete by default.

## What

Extend the `uimpl` action so that it creates a `## How` section in `change.md` when no planning sections have been started yet, with an opt-out for the existing planning flow:

- When `uimpl` runs and (a) there are no unchecked to-do items, (b) none of the planning sections (`Domain specifications`, `Functional design`, `Provisioning and configuration`, `Technical design`, `Construction`) exist yet, and (c) the `## How` section is missing from `change.md`, `uimpl` instructs the agent to append `## How` to `change.md` (using the existing `artdef_change_how.md` artifact) and stops.
- `## How` is always written to `change.md`, regardless of whether `impl.md` exists, consistent with `## How` being part of the change request rather than the implementation plan.
- When `## How` already exists, or any planning section already exists, or there are unchecked to-do items, `uimpl` behaviour is unchanged (existing review / to-do / cascade branches apply).
- A `--plan` option on `uimpl` skips the new step: with `--plan`, `uimpl` does not create `## How` and uses the existing planning sections cascade instead.

## Functional design

- [x] update: [softeng/uimpl.feature](../../../../specs/prod/softeng/uimpl.feature)
  - add: scenario for creating `## How` when it is missing, no planning section exists, and `--plan` is not set
  - add: scenario for `--plan` opting out of `## How` creation and proceeding to the existing planning sections cascade
  - place the new scenario before the existing "No unchecked to-do items" Scenario Outline

## Construction

### Tests

- [x] update: [tests/sys/softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
  - add: test asserting that when no unchecked to-dos exist, no planning section exists in `change.md`, and `## How` is absent, `uimpl` (without `--plan`) emits instructions that reference `@artdef_change_how`, targets `change.md` (not `impl.md`), and stops -- no chained self-review and no section-cascade prompt
  - add: test asserting that `uimpl --plan` on the same setup skips the How branch and emits the existing planning-sections cascade prompt (Domain specifications creation)
  - add: test asserting that when `## How` already exists in `change.md`, `uimpl` (without `--plan`) does not emit the How prompt and falls through to the existing planning-sections cascade
  - add: test asserting that when `impl.md` exists but `change.md` still lacks `## How`, the new branch still targets `change.md` (How lives on the change request, not the implementation plan)
  - add: test asserting that with unchecked to-dos present, `uimpl` (with or without `--plan`) runs the existing todos branch unchanged
- [x] update: [tests/sys/softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats) -- remediate existing tests whose setups now hit the new How branch instead of the previously expected cascade or completion output; the affected tests have `_uimpl_with_sections` (no args) or an inline empty `impl.md` plus no `## How` in `change.md`, so the new branch fires and replaces the expected output
  - update: `uimpl: scn: No unchecked to-do items: section priority and completion` (first sub-case) -- pre-populate `## How` in `change.md` so the cascade path under test is reached
  - update: `uimpl: scn: No unchecked to-do items: no specs folder skips ...` (first sub-case) -- pre-populate `## How` in `change.md` so the cascade path under test is reached
  - update: `uimpl: scn: Construction frontmatter sub-bullets (scope/breaking) appear when constr_maybe is set ...` (cases 1, 2, 3) -- pre-populate `## How` in `change.md` so the cascade path under test is reached
  - update: `uimpl: section-creation cycle chains self-review --type specs --stage A -b 4` -- pre-populate `## How` in `change.md` so the chain-emission cascade path under test is reached
  - update: `uimpl: --no-self-review on a section-creation cycle suppresses the chain` -- pre-populate `## How` in `change.md` so the no-chain cascade path under test is reached
  - rationale: pre-populating `## How` is preferred over passing `--plan` because the tests are exercising the cascade-after-`## How` flow that real change folders will follow (matching the new contract that `## How` precedes the planning cascade); `--plan` would test an opt-out path rather than the realistic flow

### Prompts

- [x] create: [bin/prompts/instr_uimpl_how.md](../../../../../bin/prompts/instr_uimpl_how.md)
  - Purpose: instruct the AI Agent to append `## How` to `${change_folder}/change.md` per `@artdef_change_how` and stop, without starting implementation and without emitting a planning-sections cascade
  - Content: heading + `## data` block instructing "Append to `${change_folder}/change.md` a `## How` section, see `@artdef_change_how`" plus a Rules line "Do not start implementation, only add the `## How` section as described above"; no `@include_chain_self_review` reference, matching the no-chain policy for content that produces no plan bullets to review (parallel to `uchange --how`)

### Script

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: `cmd_action_uimpl` usage comment block to add `[--plan]` to the documented option list
  - update: `cmd_action_uimpl` argument parser to accept a new `--plan` option (no argument; sets `opt_plan="1"`)
  - update: `cmd_action_uimpl` Implementation Plan File scan to additionally detect a `## How` heading; since `## How` lives only on `change.md`, perform the detection against `${change_folder}/change.md` regardless of whether `impl.md` exists, and set `how_exists="1"` when present
  - update: `cmd_action_uimpl` branching: after the review-pending and unchecked-to-do branches, before the existing section-creation cascade, when `opt_plan` is empty, `non_review_unchecked_count == 0`, all planning-section flags are empty (`domains_exists`, `fd_exists`, `prov_exists`, `td_exists`, `constr_exists`), and `how_exists` is empty, render the new `instr_uimpl_how` prompt with `[change_folder]="$change_folder_rel"` (the filename is embedded literally in the prompt) and return; otherwise fall through to the existing section-creation cascade unchanged

## Quick start

`uimpl` now creates the `## How` section in `change.md` when it is missing, before falling through to the existing planning-sections cascade:

- Run `uimpl` on a Working Change Folder that has no `## How` and no planning section -- the action emits instructions to author `## How` per `@artdef_change_how` and stops. The next `uimpl` invocation resumes the existing cascade (Domain specifications, Functional design, Provisioning and configuration, Technical design, Construction)
- The new branch only fires when (a) no unchecked to-dos remain, (b) no planning section has been started, and (c) `## How` is absent from `change.md`. If `## How` already exists or any planning section is present, `uimpl` keeps its existing behavior
- Pass `--plan` to opt out of How creation and go straight to the planning-sections cascade (matches the previous default for change folders created without `uchange --how`)
- `## How` is always written to `change.md` (not `impl.md`), consistent with `## How` being part of the change request rather than the implementation plan
