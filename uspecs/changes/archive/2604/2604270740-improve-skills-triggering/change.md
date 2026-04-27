---
registered_at: 2026-04-26T17:52:51Z
change_id: 2604261752-improve-skills-triggering
baseline: b4f1c5296f4aeb32a51a08988d911fc0f603aefe
archived_at: 2026-04-27T07:40:38Z
---

# Change request: Improve skills triggering via clearer descriptions and artdef references

## Why

While running `uimpl`, Claude Code did not trigger the `uspecs-sec-constr` skill when building the Construction section, so the section was authored without the skill's authoring rules.

## What

Skills should be triggered reliably when the agent works on the corresponding artifacts:

- Clearer `description` fields in each `SKILL.md` so the agent picks the right skill from its front matter
- Explicit skill-name references inside the artdef prompts emitted by `softeng.sh`, so the agent is told which skill to load when authoring each artifact

## How

- In `bin/prompts/artdef_impl_all_sections.md`, attach a `Required skill: <name>` sub-bullet to each section so the agent loads the matching `uspecs-sec-*` skill before authoring the section. The artdef is a thin menu and offloads the authoring rules to those skills. Example bullet:

  ```text
  - Construction and Quick start sections
    - Required skill: uspecs-sec-constr
  ```

- Rewrite each `SKILL.md` `description` to be a strong auto-trigger keyed on the artifact/section the agent is editing (file paths, section headings) rather than the generic "Use this skill to..." form. This is the primary fix; the `Required skill:` pointer above is a safety net when auto-trigger fails.
- Update bats system tests to lock in the new behavior: in `tests/sys/softeng.sh-action-uchange.bats` and `tests/sys/softeng.sh-action-uimpl.bats`, replace existing label assertions so each present section is verified by a single combined glob `*"<section name>"*"Required skill: uspecs-sec-<name>"*` (binds the two strings in order, locking in both the menu label and the skill pointer); negative assertions stay as two separate `!=` lines (one per absent string), since absence-of-A-followed-by-B is weaker than absence of either independently

References:

- [bin/prompts/artdef_impl_all_sections.md](../../../../../bin/prompts/artdef_impl_all_sections.md)
- [.claude/skills/](../../../../../.claude/skills/)
- [tests/sys/softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
- [tests/sys/softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)

## Construction

### Tests

- [x] update: [tests/sys/softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - update: `--specs creates specs folder and emits FD label` - replace the single section-name glob with a combined glob `*"  - Functional design section"*"Required skill: uspecs-sec-fd"*`
  - update: `without --specs and no specs folder, FD label not emitted` - assert both lines absent as two separate `!=` lines (section name and `Required skill: uspecs-sec-fd`)

- [x] update: [tests/sys/softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
  - update: every section-label assertion in present-section conditions to use a single combined glob `*"  - <section name>"*"Required skill: uspecs-sec-<name>"*` (domains, fd, prov, td, constr)
  - update: corresponding negative assertions so they check both lines are absent as two separate `!=` lines when the section is gated out

### Artdef prompts

- [x] update: [bin/prompts/artdef_impl_all_sections.md](../../../../../bin/prompts/artdef_impl_all_sections.md)
  - update: each of the five section bullets to add an indented sub-bullet `Required skill: uspecs-sec-<name>` pointing to the matching skill: domains -> `uspecs-sec-domains`, fd -> `uspecs-sec-fd`, prov -> `uspecs-sec-prov`, td -> `uspecs-sec-td`, constr -> `uspecs-sec-constr`
  - update: replicate the existing `(?...)` gates on each new sub-bullet so the pointer line appears only when its parent section appears (gates filter per-line in `emit_prompt`)

### Skill descriptions

- [x] update: [.claude/skills/uspecs-domains/SKILL.md](../../../../../.claude/skills/uspecs-domains/SKILL.md)
  - update: `description` -> auto-trigger when authoring or reviewing `uspecs/specs/{domain}/domain.md`

- [x] update: [.claude/skills/uspecs-fd/SKILL.md](../../../../../.claude/skills/uspecs-fd/SKILL.md)
  - update: `description` -> auto-trigger when authoring or reviewing `*.feature` or `*--reqs.md` under `uspecs/specs/`

- [x] update: [.claude/skills/uspecs-td/SKILL.md](../../../../../.claude/skills/uspecs-td/SKILL.md)
  - update: `description` -> auto-trigger when authoring or reviewing `tech.md`, `arch.md`, `arch-{subsystem}.md`, or `*--td.md` under `uspecs/specs/`

- [x] update: [.claude/skills/uspecs-sec-domains/SKILL.md](../../../../../.claude/skills/uspecs-sec-domains/SKILL.md)
  - update: `description` -> auto-trigger when authoring or reviewing the `## Domain specifications` section in `change.md` or `impl.md`

- [x] update: [.claude/skills/uspecs-sec-fd/SKILL.md](../../../../../.claude/skills/uspecs-sec-fd/SKILL.md)
  - update: `description` -> auto-trigger when authoring or reviewing the `## Functional design` section in `change.md` or `impl.md`

- [x] update: [.claude/skills/uspecs-sec-prov/SKILL.md](../../../../../.claude/skills/uspecs-sec-prov/SKILL.md)
  - update: `description` -> auto-trigger when authoring or reviewing the `## Provisioning and configuration` section in `change.md` or `impl.md`

- [x] update: [.claude/skills/uspecs-sec-td/SKILL.md](../../../../../.claude/skills/uspecs-sec-td/SKILL.md)
  - update: `description` -> auto-trigger when authoring or reviewing the `## Technical design` section in `change.md` or `impl.md`

- [x] update: [.claude/skills/uspecs-sec-constr/SKILL.md](../../../../../.claude/skills/uspecs-sec-constr/SKILL.md)
  - update: `description` -> auto-trigger when authoring or reviewing the `## Construction` or `## Quick start` section in `change.md` or `impl.md`

- [x] update: [.claude/skills/bats/SKILL.md](../../../../../.claude/skills/bats/SKILL.md)
  - update: `description` -> auto-trigger when authoring or reviewing `*.bats` files

- [x] update: [.claude/skills/python/SKILL.md](../../../../../.claude/skills/python/SKILL.md)
  - update: `description` -> auto-trigger when authoring or reviewing `*.py` files
