---
name: dev-change-type
description: Use this skill to add, remove, or modify a Change Request `type` (the Conventional Commits type in `change.md` frontmatter). Covers the allowed-type list, per-type `## What` guidance, and type-driven workflow branching -- either by direct agent edits or through the uspecs uchange -> uimpl cycle.
user-invocable: true
---

Develop the Change Request `type` subsystem: the set of Conventional Commits types
`uchange` may record in `change.md` frontmatter, plus the behavior each type drives.

## Subsystem map

The `type` concept is **defined by the specs** (source of truth) and **implemented by construction artifacts**, which must conform. Touch only the ones a given change needs.

Source of truth (specs govern):

- Domain design -- [context.md](../../../uspecs/specs/prod/softeng/context.md)
  - `ChangeRequest.type` entity field + the model rule that **enumerates** the allowed values (extended Conventional Commits set); the literal source of truth construction must conform to
- Functional design -- [uchange.feature](../../../uspecs/specs/prod/softeng/uchange.feature)
  - Canonical observable behavior: allowed types, missing `--type` error, fix-type fault-localization rule

Implementation (construction, conforms to the specs):

- [uchange.yaml](../../../scripts/templates/actions/uchange.yaml)
  - Operationalizes the allowed `--type` values as the agent's pick-instructions (one-line description per type)
  - Carries a **conforming copy** of the `ChangeRequest.type` list; keep the two in sync (see Key facts)
- [artdef_change_what_default.md](../../../bin/prompts/artdef_change_what_default.md)
  - Per-type `## What` tailoring for every non-`fix` type
- [artdef_change_what_fix.md](../../../bin/prompts/artdef_change_what_fix.md)
  - The `fix`-specific `## What` format (symptom / flow / corrected behavior)
- [instr_uchange.md](../../../bin/prompts/instr_uchange.md)
  - Selects the What artdef via `(?type_general)` / `(?type_fix)` conditionals
- [softeng.sh](../../../bin/softeng.sh)
  - The one seam where a type is special-cased in shell logic -- today only `fix` (`cmd_action_uchange` sets `type_fix`/`type_general`; the uimpl fix short-circuit skips the specs-tier cascade). Does not enumerate types, so ordinary types need no change here; edit only for a type with `fix`-like distinct behavior

Key facts:

- The specs are the source of truth: `ChangeRequest.type` (domain design) governs which values are legal and `uchange.feature` (functional design) governs observable behavior. The construction artifacts above only implement them.
- `ChangeRequest.type` **enumerates** the allowed values inline (extended Conventional Commits set). `uchange.yaml` carries a duplicate of that list for the agent's dispatch-time pick-instructions, so **both must be edited together** and kept identical -- the context is authoritative, `uchange.yaml` conforms. `softeng.sh` does **not** validate against an allowlist -- it only rejects an empty `--type` and special-cases `fix`; enforcement is instructional.
- Every type is `type_general` **except** `fix`, which is `type_fix`. A new ordinary type inherits general behavior automatically -- no shell change.
- Only a type that needs `fix`-like distinct behavior requires `softeng.sh` + `instr_uchange.md` + its own `artdef_change_what_<type>.md`.

## Two ways to apply a change

The Engineer decides which. Either way you make the same edits; the cycle wraps them in plan sections and review gates.

### Direct edits

When the Engineer asks you to change a type outright (no Change Request), edit the source artifacts in place following the Recipes below, then verify. Fits adding/removing an ordinary type or editing a description / `## What` bullet.

### Within the uspecs cycle

The Engineer drives the cycle -- **they** invoke `uchange` then `uimpl` (adding/removing a type is a `feat`, scope `softeng`; wording-only tweaks are `docs`/`chore`). When the Engineer runs them, make the Recipe edits below, placing each in the plan section that matches its artifact's layer in the Subsystem map, and author that section with its skill: [uspecs-sec-domains](../uspecs-sec-domains/SKILL.md) (domain design), [uspecs-sec-fd](../uspecs-sec-fd/SKILL.md) (functional design), [uspecs-sec-constr](../uspecs-sec-constr/SKILL.md) (construction).

## Recipes

Artifacts are named in short form below; their paths and roles are in the Subsystem map above.

### Add an ordinary type

Start at the source of truth, then implement:

1. `context.md`: add the value + one-line description to the `ChangeRequest.type` enumeration -- the authoritative decision.
2. `uchange.yaml`: add the matching `` - `<type>` -- <one-line description> `` bullet under the allowed values, wording identical to the context.
3. `artdef_change_what_default.md`: add a bullet under "Tailor the `## What` items to the `type:` frontmatter value" stating what `## What` should assert for this type.
4. `uchange.feature`: add/adjust a scenario if observable behavior changed.
5. Verify (see below).

### Modify a type's description or What guidance

The one-line description lives in **both** `context.md` (source of truth) and `uchange.yaml` -- edit both identically. `## What` tailoring lives in `artdef_change_what_default.md`. No shell change.

### Add a type with distinct behavior (like `fix`)

1. `context.md`: add the value to the `ChangeRequest.type` enumeration (source of truth); if its distinct behavior is Engineer-observable, capture the rule here too.
2. `uchange.yaml`: add the matching value + description.
3. `softeng.sh` `cmd_action_uchange`: set a `type_<name>` flag beside the `type_fix`/`type_general` block and add it to the `context_vars` map passed to the prompt.
4. `instr_uchange.md`: add a `(?type_<name>)` conditional selecting a new artdef.
5. Create `bin/prompts/artdef_change_what_<name>.md` with that type's `## What` format.
6. If the type changes the uimpl cascade (as `fix` skips the specs tier), update `softeng.sh` uimpl branching and [uimpl.feature](../../../uspecs/specs/prod/softeng/uimpl.feature).
7. Update `uchange.feature` as needed.

### Remove a type

Delete the value from the `ChangeRequest.type` enumeration in `context.md` (source of truth), then its matching `uchange.yaml` bullet and its `artdef_change_what_default.md` bullet. Remove any dedicated artdef/flag/conditional if it had distinct behavior. Update `uchange.feature`.

## Verify

Do not run tests unless requested; when you do:

```bash
python3 tests/run-tests.py tests/sys/softeng.sh-action-uchange.bats
python3 tests/run-tests.py tests/sys/softeng.sh-action-uimpl.bats   # only if uimpl branching changed
```

Confirm the implementation matches the spec: the `raw_text` block in `uchange.yaml` (what the agent is instructed to choose from) must list exactly the types `ChangeRequest.type` allows.
