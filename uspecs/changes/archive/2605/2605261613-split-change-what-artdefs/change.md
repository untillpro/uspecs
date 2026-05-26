---
change_id: 2605260711-split-change-what-artdefs
type: refactor
---

# Change request: Split change request section artdefs

## Why

The change-request prompt currently groups heading shape, optional Resolves block, Why guidance, default What guidance, and fix-specific What guidance in one artifact definition. Separating those concerns will make the authoring instructions easier to evolve while preserving the existing change request output contract.

## What

This is a prompt-artifact refactor with no intended behavior change to generated change request content: existing users should still receive the same section order, authoring requirements, and optional issue-reference behavior.

- Resolves, Why, default What, and fix-specific What guidance are each owned by focused artifact definitions.
- The change creation instructions remain the single source of ordering for the final change request body.
- The default What guidance applies to non-fix change types, while fix change types receive only the fix-specific What format.
- Existing optional issue reference behavior is preserved: reference guidance appears only for fetchable issue flows.
- Existing prompt rendering remains compatible with current downstream actions.

## How

Decisions:

- Split `artdef_change_why_what.md` into focused prompt artifacts for the change heading, Why guidance, default What guidance, and fix-specific What format while keeping `artdef_change_resolves.md` as the existing Resolves artifact.
- Update `instr_uchange.md` so it composes the final change request body from the focused artifacts in the existing order, leaving the instruction as the ordering source.
- Preserve the existing `uchange` behavior contract: non-fetchable changes render Why and What, fetchable issue flows render Resolves before Why, and `fix` changes use only the fix-specific What shape.

Out of scope:

- Changing generated change request section order or content semantics.
- Changing issue fetching, branch naming, implementation planning, or downstream PR body behavior.

References:

- [change heading artifact](../../../../../bin/prompts/artdef_change_heading.md)
- [existing Resolves artifact](../../../../../bin/prompts/artdef_change_resolves.md)
- [change Why artifact](../../../../../bin/prompts/artdef_change_why.md)
- [default What artifact](../../../../../bin/prompts/artdef_change_what_default.md)
- [fix What artifact](../../../../../bin/prompts/artdef_change_what_fix.md)
- [change creation instructions](../../../../../bin/prompts/instr_uchange.md)
- [uchange behavior specification](../../../../../uspecs/specs/prod/softeng/uchange.feature)
- [issue handling cross-action hub](../../../../../uspecs/specs/prod/softeng/cross/issue-handling.feature)

## Construction

- [x] update: [softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - update assertions that currently expect `<artdef id="artdef_change_why_what"` to expect `<artdef id="artdef_change_heading"`, `<artdef id="artdef_change_why"`, `<artdef id="artdef_change_what_default"`, and `<artdef id="artdef_change_what_fix"` instead
  - add assertions that `artdef_change_why_what` is no longer emitted after `instr_uchange.md` migrates to the focused artifacts
  - keep coverage that non-fetchable output omits `artdef_change_resolves`, fetchable output includes it, and fetchable instructions place Resolves between the heading and Why
  - keep assertions that rendered guidance preserves type-specific What behavior and the fix-specific symptom, flowchart, and corrected-behavior format after the split

- review

- [x] create: [artdef_change_heading.md](../../../../../bin/prompts/artdef_change_heading.md)
  - artifact definition for the change request H1 and title rules only
  - preserve the title constraints: short noun phrase, sentence case, no trailing period, no file paths or symbol names

- [x] create: [artdef_change_why.md](../../../../../bin/prompts/artdef_change_why.md)
  - artifact definition for the `## Why` section shape and fetchable issue distillation rule
  - preserve the 1-3 sentence reason/purpose guidance and the rule to distill fetched issues without verbatim restatement

- [x] create: [artdef_change_what_default.md](../../../../../bin/prompts/artdef_change_what_default.md)
  - artifact definition for default `## What` guidance used by all non-fix change types
  - preserve the behavior-claim rules and per-type guidance for `feat`, `refactor`, `perf`, `style`, `docs`, `build`, `ci`, `chore`, `test`, and `revert`

- [x] create: [artdef_change_what_fix.md](../../../../../bin/prompts/artdef_change_what_fix.md)
  - artifact definition for the fix-only `## What` format
  - preserve the symptom, flowchart, and corrected behavior claim requirements

- [x] update: [instr_uchange.md](../../../../../bin/prompts/instr_uchange.md)
  - compose the change request body from `@artdef_change_heading`, `@artdef_change_refs` gated on fetchable issue flows, `@artdef_change_why`, and one What format selected from `@artdef_change_what_default` or `@artdef_change_what_fix`
  - keep `@artdef_change_how` and implementation-section inclusion behavior unchanged

- [x] remove: [artdef_change_why_what.md](../../../../../bin/prompts/artdef_change_why_what.md)
  - remove the combined artifact after all prompt references and tests have migrated to the focused artifacts
