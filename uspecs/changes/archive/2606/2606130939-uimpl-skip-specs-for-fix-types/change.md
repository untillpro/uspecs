---
change_id: 2606122239-uimpl-skip-specs-for-fix-types
type: feat
domains: [prod]
scope: [softeng]
---

# Change request: Skip specs cascade in uimpl for fix-type changes

## Why

Bug fixes rarely benefit from authoring Domain, Functional design, or Technical design specifications, yet today `uimpl` proposes those specs-tier sections regardless of the change request `type:`. The unnecessary cascade adds overhead and friction when the Engineer just wants to land a fix.

## What

- When the active change request has `type: fix`, the `uimpl` action in the `prod` softeng context does not propose or require specs-tier sections (Domain specifications, Functional design, Technical design).
- The cascade jumps to the next applicable non-specs step: Provisioning and configuration (when relevant) or Construction.
- Construction is still proposed and appended for fix-type changes; the work plan is preserved.
- `## How` is still authored on `change.md` for fix-type changes (it is a change-request artifact, not part of the plan cascade).
- Change requests with any other `type:` value retain the existing cascade behavior unchanged.

## How

Decisions:

- Read the change request `type:` from `change.md` frontmatter in `cmd_action_uimpl` using the existing `md_read_frontmatter_field` helper.
- When `type == fix`, force-clear the specs-tier maybe gates (`domains_maybe`, `fd_maybe`, `td_maybe`) before the section-creation branch runs. Leave `prov_maybe` and `constr_maybe` intact so the cascade still proposes Provisioning (when applicable) and Construction.
- Keep the `## How` authoring branch unchanged -- it gates on `how_exists` against `change.md` and is independent of the plan cascade.
- Self-review chaining around Construction creation is unchanged (already covered by the existing `Auto-invoke self-review after section creation` outline).
- Update `uimpl.feature` to document the fix-type specs-tier short-circuit alongside the existing cascade scenarios.

Out of scope:

- Changing the behavior of other actions (`uchange`, `upr`, `uarchive`, etc.) based on `type: fix`.
- Reclassifying which impl-plan sections count as "plan sections".
- Backfilling or auto-migrating already-authored non-fix change requests.

References:

- [uimpl action implementation](../../../../../bin/softeng.sh)
- [uimpl feature spec](../../../../../uspecs/specs/prod/softeng/uimpl.feature)
- [uimpl system tests](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
- [md_read_frontmatter_field helper](../../../../../bin/_lib/utils.sh)
- [instr_uimpl prompt template](../../../../../bin/prompts/instr_uimpl.md)

## Functional design

- [x] update: [softeng/uimpl.feature](../../../../specs/prod/softeng/uimpl.feature)
  - add: scenario establishing that when `change.md` frontmatter is `type: fix` and `## How` exists with no unchecked to-do items, `uimpl` skips the specs-tier cascade steps (Domain specifications, Functional design, Technical design) and proceeds to the next applicable cascade step (Provisioning and configuration or Construction)

## Construction

- [x] update: [sys/softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
  - add: test asserting that a change folder with `type: fix` frontmatter and `## How` present (no plan sections) emits the `Provisioning and configuration` and `Construction` blocks but omits `Domain specifications`, `Functional design`, and `Technical design` blocks (mirror the pattern of `scn: No unchecked to-do items: no specs folder skips ...`)
  - add: test asserting that for `type: fix`, only `Construction` is emitted when `prov` already exists (specs-tier still skipped)
  - add: test asserting that an explicit non-fix `type:` (use `type: feat`) retains the full cascade — Domain specifications, Functional design, Technical design blocks are still emitted (regression guard for the type comparison)
  - test fixtures: write `type:` into `change.md` frontmatter directly (the existing `_make_change_folder` helper writes only `change_id:`); do not modify the helper
- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: `cmd_action_uimpl` to read `type:` from change.md frontmatter via `md_read_frontmatter_field` after `change_folder_rel` is resolved
  - update: when `type == fix`, clear `domains_maybe`, `fd_maybe`, and `td_maybe` after the existing cascade-gate computation, leaving `prov_maybe` and `constr_maybe` intact
  - add: a brief comment near the clearing block referencing the `Fix-type change skips specs-tier cascade steps` scenario in `uimpl.feature`
