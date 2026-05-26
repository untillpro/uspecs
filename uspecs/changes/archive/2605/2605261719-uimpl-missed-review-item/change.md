---
change_id: 2605261620-uimpl-missed-review-item
type: fix
scope: softeng
---

# Change request: Review boundary in implementation instructions

## Why

Implementation guidance should stop at explicit review checkpoints before moving to later Construction work. When `uimpl` emits unchecked tasks from both sides of a pending Review Item, the agent can complete work that should wait for a later implementation cycle.

## What

The implementation action emits unchecked todo items from both sides of a pending Review Item instead of stopping the selected todo run at the review boundary.

```text
user runs implementation action for a change
      |
      v
Construction section contains unchecked tasks, then a pending Review Item, then more unchecked tasks
      |
      v
pending item collector       <-- fault: treats pending Review Item as filtered item, not boundary
      |
      v
todo-focused agent instructions include items before and after review   (symptom)
```

The implementation action stops the selected todo run at a pending Review Item so later unchecked items are left for a subsequent implementation cycle.

## How

Decisions:

- Treat any pending review item form (`- review`, `- Review`, `- [ ] review`, `- [ ] Review`) as a boundary that closes the current unchecked-collection area.
- When the scanner encounters a pending review boundary after collecting one or more non-review unchecked items, stop processing further todo items for this `uimpl` cycle so later unchecked items remain for a subsequent cycle.
- Preserve the review-only path: when the pending review item is the only pending item, emit `instr_uimpl_review_pending` instead of todo instructions.
- Localize the fix to the existing `cmd_action_uimpl` line scanner in `bin/softeng.sh`; adjust review-item handling so it closes/stops the unchecked area instead of opening or continuing a collectable item.

Out of scope:

- Checked review items (`- [x] review`) -- completed review markers must not block later unchecked work.
- Changing the review item matcher beyond the existing pending review forms.
- Reworking the scanner into multiple passes.
- The branching logic that selects between `instr_uimpl_todos` and `instr_uimpl_review_pending`, and the self-review chain selection.

References:

- [uimpl line scanner and area-close helper](../../../../../bin/softeng.sh)
- [todo emission template](../../../../../bin/prompts/instr_uimpl_todos.md)
- [uimpl behavior specification](../../../../../uspecs/specs/prod/softeng/uimpl.feature)
- [uimpl bats coverage](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
- [previous bare-review-item fix](../../../../../uspecs/changes/archive/2605/2605211034-uimpl-review-item/change.md)

## Functional design

- [x] update: [softeng/uimpl.feature](../../../../../uspecs/specs/prod/softeng/uimpl.feature)
  - add: scenario covering a Construction todo run where unchecked tasks appear before and after a pending Review Item
  - require: `uimpl` emits only the unchecked tasks before the pending Review Item in the current todo-focused instruction block
  - require: unchecked tasks after the pending Review Item are left for a later implementation cycle

## Construction

- [x] update: [sys/softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
  - update existing review-item coverage so a pending Review Item bounds the current emitted todo block instead of allowing following unchecked items through
  - cover unchecked Construction to-do items before and after each pending Review Item form
  - assert `instr_uimpl_todos` includes only the unchecked item before the pending Review Item
  - assert the pending Review Item itself and unchecked items after it are omitted from the emitted todo block
  - preserve coverage that a pending Review Item with no preceding unchecked item emits `instr_uimpl_review_pending`

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - change the `cmd_action_uimpl` line scanner so pending Review Items close the current unchecked-collection area and stop todo collection for the current cycle
  - preserve review-only behavior: when the pending Review Item is the only pending item, emit `instr_uimpl_review_pending`
  - preserve checked review markers as non-pending review items
  - keep self-review chain selection based on the section of the first emitted non-review unchecked item
