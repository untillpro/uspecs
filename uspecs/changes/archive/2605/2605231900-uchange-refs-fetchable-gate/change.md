---
registered_at: 2026-05-23T18:41:35Z
change_id: 2605231841-uchange-refs-fetchable-gate
type: fix
scope: softeng
baseline: 21bc095cfe02d01ef3c81148478ac4079bf6b499
archived_at: 2026-05-23T19:00:04Z
---

# Change request: Refs block leaks into non-fetchable uchange change.md

## Why

A recent refactor of `artdef_change_why_what.md` (commit `7f07373`) accidentally dropped the `(?fetchable_maybe)` gate on the "Insert Refs:" rule. As a result the rendered `uchange` instructions now always carry the `Refs:` rule and (via dependency walk on the filtered body) the `artdef_change_refs` block, even when `--fetchable` is not passed. The non-fetchable shape is supposed to be Why + What only, with no Refs, so the regression silently produces malformed `change.md` files.

## What

Running `uchange` without `--fetchable` renders an `<artdef id="artdef_change_refs">` block and a Rules line instructing the agent to insert a `Refs:` section between the H1 and `## Why`, so the agent appends a `Refs:` block to a `change.md` that has no associated issue file.

```text
uchange invoked without --fetchable
          |
          v
softeng.sh sets fetchable_maybe=""
          |
          v
emit_prompt walks artdef_change_why_what.md
          |
          v
_emit_filter_body keeps the unconditional "Insert Refs:" rule line   <-- fault: (?fetchable_maybe) missing
          |
          v
dep-scan on filtered body picks up @artdef_change_refs and queues it
          |
          v
rendered instructions tell the agent to add Refs: to change.md   (symptom)
```

The non-fetchable `uchange` flow renders neither the `artdef_change_refs` block nor the "Insert Refs:" rule, restoring the documented Why + What shape; the `--fetchable` flow is unchanged.

## How

Decisions:

- Restore the `(?fetchable_maybe)` conditional on the "Insert Refs:" Rules line in `bin/prompts/artdef_change_why_what.md`; the conditional was the original gate added by PR #97 and was dropped by a later refactor commit
- Add negative assertions to the existing non-fetchable test `uchange: scn: Issue reference provided` in `tests/sys/softeng.sh-action-uchange.bats` (assert `artdef_change_refs` block absent and "Insert ... Refs: ... block" rule text absent) so the regression cannot recur
- No changes to `bin/softeng.sh` or the prompt-emission engine in `bin/_lib/utils.sh`: `fetchable_maybe` is already wired through `cmd_action_uchange` and the dep-walk runs after conditional filtering, so dropping the rule line correctly drops the `artdef_change_refs` dependency

Out of scope:

- Auditing other artdef files for similar dropped conditionals
- Reworking the artdef dependency-resolution order in `_emit_collect`

References:

- [artdef being fixed](../../../../../bin/prompts/artdef_change_why_what.md)
- [system test being extended](../../../../../tests/sys/softeng.sh-action-uchange.bats)
- [prompt emission and conditional filter](../../../../../bin/_lib/utils.sh)
- [prior change that introduced the gated rule](../../../archive/2605/2605201700-uchange-fetchable-refs-shape/change.md)

## Construction

- [x] update: [sys/softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - extend test `uchange: scn: Issue reference provided` with two negative assertions: `<artdef id="artdef_change_refs"` substring is absent from `$output`, and the literal "Insert ... Refs: ... block" rule text is absent from `$output`

- [x] update: [prompts/artdef_change_why_what.md](../../../../../bin/prompts/artdef_change_why_what.md)
  - append `(?fetchable_maybe)` to the "Insert the `Refs:` block from `@artdef_change_refs` between the H1 and `## Why`" rule line in the `Rules` section, restoring the gate dropped by commit `7f07373`
