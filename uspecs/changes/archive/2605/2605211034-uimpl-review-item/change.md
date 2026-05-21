---
registered_at: 2026-05-20T21:41:34Z
change_id: 2605202141-uimpl-review-item
type: fix
scope: softeng
baseline: fecde057322f2f40221c01b1e730d457e1138dde
archived_at: 2026-05-21T10:34:11Z
---

# Change request: Respect review item in uimpl command

## Why

The `uimpl` command did not respect a requested `review` item formatted as `- review`, so an implementation workflow could omit review work the caller explicitly asked for. Instead, `uimpl` emitted next todo items to the agent, making the command output unreliable for review-focused implementation planning.

## What

Deliver a fix for the `uimpl` item handling:

- Symptom: when `uimpl` is invoked with the exact item format `- review`, the generated implementation instructions do not honor that requested review work and instead emit next todo items to the agent.

- Flow: the caller provides the item `- review`, the `uimpl` action dispatches and interprets the requested work items, the faulty item-handling step fails to preserve or apply `review`, and the resulting instructions emit next todo items to the agent instead of the requested review requirement.

- Corrected behavior: `uimpl` recognizes and respects the `review` item so generated implementation guidance includes the requested review work.

## How

Decisions:

- Keep the fix in the existing `cmd_action_uimpl` single-pass scanner and branching logic in `bin/softeng.sh`.

- Treat bare review items such as `- review` as review-only work when no non-review unchecked to-do items are present, not as a reason to continue into the planning-section cascade.

- Preserve the existing behavior for checkbox review items and mixed todo lists: `uimpl` still emits `instr_uimpl_review_pending` only when review is the only pending item, and emits `instr_uimpl_todos` when non-review todo items remain.

- Extend `tests/sys/softeng.sh-action-uimpl.bats` with focused system coverage proving that an implementation plan containing only the exact lowercase bare item `- review` emits `instr_uimpl_review_pending` instead of next todo instructions.

References:

- [uimpl action dispatcher](../../../../../bin/softeng.sh)
- [uimpl system tests](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
- [uimpl feature scenarios](../../../../../uspecs/specs/prod/softeng/uimpl.feature)
- [review-pending prompt](../../../../../bin/prompts/instr_uimpl_review_pending.md)
- [todo-items prompt](../../../../../bin/prompts/instr_uimpl_todos.md)

## Functional design

- [x] update: [softeng/uimpl.feature](../../../../../uspecs/specs/prod/softeng/uimpl.feature)
  - add: scenario covering an implementation plan whose only pending item is the exact lowercase bare review item `- review`
  - update: review-item behavior to require `uimpl` to emit the review-pending instruction instead of next todo instructions for that item format

## Construction

- [x] update: [sys/softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
  - add: regression coverage for an implementation plan whose only pending item is the exact lowercase bare review item `- review`
  - assert: `uimpl` emits `instr_uimpl_review_pending` and does not emit `instr_uimpl_todos` or next todo instructions for that item format

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - fix: classify bare review items such as `- review` as review-only pending work when counting non-review unchecked items
  - preserve: mixed todo lists still emit next todo instructions for non-review items, while review-only inputs emit the review-pending instruction
