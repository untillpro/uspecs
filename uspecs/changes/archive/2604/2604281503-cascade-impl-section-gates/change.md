---
registered_at: 2026-04-28T09:28:47Z
change_id: 2604280928-cascade-impl-section-gates
baseline: 613eb31e0b2cf0c6934702bfb60e9fb7f01a175c
archived_at: 2026-04-28T15:03:14Z
---

# Change request: Cascade implementation section gates with permissive heading detection

## Why

During a `uimpl` run, `artdef_impl_all_sections` still offered the `Functional design` bullet even though that section already existed in the change file. Two issues compound to produce this: `cmd_uimpl` in `softeng.sh` matches the long heading `## Functional design specifications` while every `uspecs-sec-*` skill and recently authored change files use the short `## Functional design`, so `fd_exists` is never set; and the artdef gates do not encode the priority cascade described in `uimpl.feature` (domains -> fd -> prov -> td -> constr), so a later-stage section never suppresses earlier candidates.

## What

Section gating in `artdef_impl_all_sections` should match the priority cascade described in `uimpl.feature`, and section detection should be tolerant of heading-name variations:

- Detection in `cmd_uimpl` uses permissive globs of the form `##*<canonical name>*` so any heading containing the canonical section name is recognised, regardless of heading level or trailing words (matches `## Functional design`, `## Functional design specifications`, and similar variants without code changes when authoring conventions evolve)
- Per-section `_maybe` flags computed from `*_exists` and `specs_maybe` with cascading semantics, so a later-stage section suppresses earlier candidates
- Artdef bullets gated by a single `(?*_maybe)` flag each, replacing the current `(?specs_maybe)(?!*_exists)` combination
- Bats coverage extended for the cascade behaviour and for the permissive heading detection

## How

- In `bin/softeng.sh` `cmd_uimpl`, change all five section case patterns to permissive globs of the form `"##"*"<canonical name>"*` so detection accepts any heading level and any text containing the canonical name. Concretely: `"##"*"Domain specifications"*`, `"##"*"Functional design"*`, `"##"*"Provisioning"*`, `"##"*"Technical design"*`, `"##"*"Construction"*`. After the parsing loop, compute `domains_maybe`, `fd_maybe`, `prov_maybe`, `td_maybe`, `constr_maybe` from `*_exists` and `specs_maybe` using the cascade: each `_maybe` is true only when its own section is absent and no later-stage section exists; spec-tier flags additionally require `specs_maybe`. Pass the `_maybe` flags into `context_vars` for `emit_prompt`.

- Mirror the same `_maybe` computation in `cmd_uchange`, where all `*_exists` are empty so the cascade collapses to today's behaviour (everything gated by `specs_maybe` for the spec tier and unconditionally on for prov/constr).

- In `bin/prompts/artdef_impl_all_sections.md`, replace each bullet's `(?specs_maybe)(?!*_exists)` pair with a single `(?<section>_maybe)` gate, removing section-priority knowledge from the artdef.

- In `tests/sys/softeng.sh-action-uimpl.bats`, add cascade scenarios: empty file (all `_maybe` follow `specs_maybe`), only FD present (domains and fd suppressed; prov/td/constr remain), only TD present (domains/fd/prov/td suppressed; only constr remains), only Construction present (all suppressed), `--specs` off (domains/fd/td gated out regardless of `*_exists`). Add at least one scenario per section that uses a non-canonical heading variant (e.g. `## Functional design specifications`, `### Technical design`) to lock in the permissive detection.

References:

- [bin/softeng.sh](../../../../../bin/softeng.sh)
- [bin/prompts/artdef_impl_all_sections.md](../../../../../bin/prompts/artdef_impl_all_sections.md)
- [tests/sys/softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)

## Construction

### Tests

- [x] update: [tests/sys/softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
  - add: scenario "permissive heading detection -- canonical short forms" that calls `_uimpl_with_sections` after substituting the helper to emit `## Functional design` and `## Technical design` (canonical short forms produced by the `uspecs-sec-fd` / `uspecs-sec-td` skills) and asserts the corresponding section bullets are suppressed in the next-section menu (this is the original bug)
  - add: scenario "permissive heading detection -- deeper heading levels" that emits each section heading at level h3 (e.g. `### Construction`) and asserts the corresponding bullet is suppressed
  - add: scenario "permissive heading detection -- non-canonical trailing words" that emits e.g. `## Functional design notes` and asserts the bullet is suppressed (locks in `*` glob behaviour after the canonical name)
  - keep: existing long-form scenarios unchanged so they continue to verify backward compatibility under the permissive detection

### Script

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: in `cmd_uimpl` the five `case` patterns at lines ~846-850, replace the literal-prefix patterns with permissive globs - `"##"*"Domain specifications"*` -> `domains_exists`, `"##"*"Functional design"*` -> `fd_exists`, `"##"*"Provisioning"*` -> `prov_exists`, `"##"*"Technical design"*` -> `td_exists`, `"##"*"Construction"*` -> `constr_exists`. Pattern order must keep `Construction` last so it does not shadow the others
  - add: after the parsing loop and after `specs_maybe` is computed (line ~913), derive the cascade `_maybe` flags from `*_exists` and `specs_maybe`:
    - `domains_maybe`: set only when `specs_maybe="1"` and none of `domains_exists`, `fd_exists`, `prov_exists`, `td_exists`, `constr_exists` is set
    - `fd_maybe`: set only when `specs_maybe="1"` and none of `fd_exists`, `prov_exists`, `td_exists`, `constr_exists` is set
    - `prov_maybe`: set only when none of `prov_exists`, `td_exists`, `constr_exists` is set
    - `td_maybe`: set only when `specs_maybe="1"` and none of `td_exists`, `constr_exists` is set
    - `constr_maybe`: set only when `constr_exists` is empty
  - update: `impl_vars` map at lines ~935-946 to pass `domains_maybe`, `fd_maybe`, `prov_maybe`, `td_maybe`, `constr_maybe` instead of `specs_maybe` and the five `*_exists` keys (`change_folder`, `impl_file`, `specs_folder`, `change_file_rel_path` stay)
  - update: `cmd_uchange` `context_vars` map at lines ~712-723, drop the five empty `*_exists` keys and `specs_maybe`, add `domains_maybe`, `fd_maybe`, `prov_maybe`, `td_maybe`, `constr_maybe` computed from `specs_maybe` (since all `*_exists` are empty, the cascade collapses to: spec-tier flags equal `specs_maybe`, prov/constr always `"1"`)

### Artdef prompts

- [x] update: [bin/prompts/artdef_impl_all_sections.md](../../../../../bin/prompts/artdef_impl_all_sections.md)
  - update: each of the five section bullets, replace the trailing `(?specs_maybe)(?!*_exists)` (or `(?!*_exists)`) gate combination with a single positive `(?<name>_maybe)` gate - domains -> `(?domains_maybe)`, fd -> `(?fd_maybe)`, prov -> `(?prov_maybe)`, td -> `(?td_maybe)`, constr -> `(?constr_maybe)`. The `Required skill:` sub-bullet on each line keeps its existing gate (which already mirrors the parent line)

- [x] update: [bin/prompts/instr_uimpl.md](../../../../../bin/prompts/instr_uimpl.md)
  - update: replace `(?constr_exists)` with `(?!constr_maybe)` on the "implementation plan is completed" line and `(?!constr_exists)` with `(?constr_maybe)` on the "Append the following artifacts" line. `cmd_uimpl` no longer passes `constr_exists` in `impl_vars`, so this file fails with "unknown condition variable" until updated

- [x] update: [bin/prompts/instr_uimpl_todos.md](../../../../../bin/prompts/instr_uimpl_todos.md)
  - update: shorten the first rule from `Do not perform work outside this list. If scope seems incomplete relative to narrative sections ("Why"/"What"), stop and inform the user rather than expanding scope.` to `Do not perform work outside this list`

### Engine fixes (emit_prompt processing order)

Running `usync` against the cascade work surfaced two latent bugs in `emit_prompt` where free-form text carried in a substituted variable (the git diff in `${diff}`) was incorrectly processed by the template engine. Both required to validate the cascade end-to-end via `usync`.

- [x] update: [bin/_lib/utils.sh](../../../../../bin/_lib/utils.sh)
  - split: `_emit_process_body` into `_emit_filter_body` (conditional filtering + unbound-variable check) and `_emit_substitute_body` (`${KEY}` replacement)
  - update: `_emit_collect` now runs filter -> `@artdef_*` dep scan (on the pre-substitution body) -> substitute. Both the unbound check and the dep scan operate on the unsubstituted body so that `${KEY}` literals or `` `@artdef_*` `` references carried inside substituted values (e.g. a git diff embedded via `${diff}`) are not mistaken for template placeholders or dependencies

- [x] update: [tests/unit/utils-emit-prompt.bats](../../../../../tests/unit/utils-emit-prompt.bats)
  - add: scenario "substituted value containing dollar-brace literal is not flagged as unbound" -- verifies a `${diff}` value containing literal `${impl_file}` text passes through without an unbound-variable error
  - add: scenario "substituted value containing @artdef reference does not trigger dep collection" -- verifies a `${diff}` value containing a literal `` `@artdef_nonexistent` `` does not cause the dep scanner to attempt loading it
