---
registered_at: 2026-05-17T17:54:40Z
change_id: 2605171754-uchange-how-plan-options
type: feat
scope: softeng
breaking: true
baseline: b7d780b6e8e909c2cad2ab937f7437b17ea2e028
archived_at: 2026-05-17T21:59:15Z
---

# Change request: Add `--how` and `--plan` options to `uchange`

## Why

Today `uchange` always emits the impl sections menu by default and only emits the `## How` section when `--no-impl` is passed - an inverted, hard-to-discover semantic. The flag name `--no-impl` also conflates two unrelated concerns (whether to author the implementation plan, and whether to later execute it). Splitting these concerns into explicit, positive opt-in flags makes the action surface honest and leaves room for a future `--impl` flag meaning "execute the plan" without re-overloading existing names.

## What

Introduce positive opt-in flags on `uchange`:

- `--how` causes the `## How` section to be appended to `change.md`. Default: not generated.
- `--plan` causes the impl sections menu to be appended and `uimpl` to be auto-invoked. Default: not generated.
- `--no-impl` is retained as a parsed no-op for backwards compatibility when passed alone, equivalent under the new defaults to invoking `uchange` without any of these flags. Combining `--no-impl` with `--how` or `--plan` is an error. The flag is preserved as the long-term BC partner of a future `--impl` flag (which will mean "execute the plan").
- `--specs` and `--plan` are independent: `--specs` keeps its filesystem side-effect of creating the empty `uspecs/specs/` folder regardless of other flags, but the Domain / FD / TD bullets in the impl sections menu only emit when `--plan` is also passed.

Out of scope for this change: the `--impl` flag itself (reserved for a follow-up).

## How

Decisions:

- Drive the existing `(?no_impl)` gate in `bin/prompts/instr_uchange.md` from a new positive `how_maybe` context var fed by `--how`, aligning with the established `*_maybe` naming used for `fd_maybe`, `prov_maybe`, `td_maybe`, `constr_maybe`, `domains_maybe`

- Keep `impl_maybe` (and the cascade flags `domains_maybe` / `fd_maybe` / `td_maybe` derived from it) intact, but flip its derivation in `cmd_action_uchange` to be driven by `--plan` instead of by the absence of `--no-impl`

- Accept `--no-impl` in the arg-parsing loop; treat it as a no-op when passed alone, but exit with `--no-impl cannot be combined with --how or --plan` when combined with either positive flag, mirroring the existing `--branch` / `--no-branch` mutual-exclusion check in `cmd_action_uchange`

- Gate the agent-side auto-invocation of `uimpl` on `--plan` - the spec line in `uchange.feature` "uimpl action is invoked automatically" moves from the default scenario onto a `--plan`-gated scenario

- Update the system tests to lock in the new default (neither How nor impl bullets emitted), add positive `--how` and `--plan` cases, keep a `--no-impl` BC test asserting equivalence to default, and add `--no-impl --plan` / `--no-impl --how` error scenarios

- Keep internal vocabulary (`impl_maybe`, `@include_impl_sections`, `uimpl`) on the `impl` stem; the user-facing `--plan` flag and the internal `impl_*` names coexist intentionally

- Keep `--specs` orthogonal to `--plan`: `--specs` still unconditionally creates `uspecs/specs/` as a filesystem side-effect, but the spec-tier bullets (Domain / FD / TD) remain gated by the existing `impl_maybe AND specs_maybe` cascade, so they only emit when `--plan` is also passed; the `--specs option` scenario in `uchange.feature` drops its old artdef-reception assertion (that effect now belongs to `--plan`) and the two flags' combination is not described as a separate scenario

- Agent dispatch is explicit-only for the new flags: `--how` and `--plan` are forwarded only when the engineer literally typed them. No new rule is added to `scripts/templates/actions/uchange.yaml::raw_text` or to the per-action `uchange` sections in `AGENTS.md` / `CLAUDE.md`; the existing convention (the agent forwards options the user typed, otherwise follows the explicit derivation rules already listed) covers this the same way it covers `--branch` / `--no-branch` / `--no-impl` today. Only the `options:` line in the yaml is updated to list `--how` and `--plan`.

Out of scope:

- Adding the `--impl` flag itself - reserved for a follow-up change once execution semantics are designed
- Renaming `impl_maybe` / `@include_impl_sections` / `uimpl` to plan-* vocabulary
- Introducing a `--no-plan` synonym for `--no-impl`
- Inferring `--how` / `--plan` from natural-language cues in the user's prompt

References:

- [uchange feature spec](../../../../specs/prod/softeng/uchange.feature)
- [uchange action implementation](../../../../../bin/softeng.sh)
- [uchange instruction template](../../../../../bin/prompts/instr_uchange.md)
- [impl sections menu](../../../../../bin/prompts/include_impl_sections.md)
- [How section artdef](../../../../../bin/prompts/artdef_change_how.md)
- [uchange action manifest](../../../../../scripts/templates/actions/uchange.yaml)
- [uchange system tests](../../../../../tests/sys/softeng.sh-action-uchange.bats)
- [historical change introducing --no-impl](../../../archive/2603/2603111439-uchange-invoke-uimpl/change.md)

## Functional design

- [x] update: [softeng/uchange.feature](../../../../specs/prod/softeng/uchange.feature)
  - update: Rule "Core behavior" Scenario Outline "Mandatory options only" - flip the "And uimpl action is invoked automatically" step to "And uimpl action is not invoked automatically"; defaults no longer auto-invoke uimpl
  - update: Scenario "--no-impl option" under Rule "Options" - rename to "--no-impl option is a backwards-compatible no-op" and rewrite the assertion to "the outcome is identical to invocation without the flag"
  - add: Scenario "--how option" under Rule "Options" - base change request created with `## How` section appended and uimpl not invoked automatically
  - add: Scenario "--plan option" under Rule "Options" - base change request created and uimpl invoked automatically
  - add: Scenario Outline "--no-impl combined with --how or --plan" under Rule "Edge cases" - error `--no-impl cannot be combined with --how or --plan` is displayed and the change request is not created
  - update: Scenario "--specs option" under Rule "Options" - drop the "AI Agent receives Domain / FD / TD artdefs" assertion since under the new defaults that effect requires `--plan`; keep the folder-creation assertion

## Construction

### Tests

- [x] update: [sys/softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - update: `uchange: scn: No options: default branch` and `uchange: scn: No options: non-default branch` - assert that neither the `artdef_change_how` artdef nor the `- Functional design section` impl-menu bullet is emitted under defaults
  - update: `uchange: scn: --no-impl option` - drop the old "How section emitted" / "FD bullet not emitted" assertions and assert instead that the output is byte-equivalent to a no-flag invocation (BC no-op)
  - add: `uchange: scn: --how option` - invoke with `--how`, assert `artdef_change_how` is emitted and the impl-menu bullets are not
  - add: `uchange: scn: --plan option` - invoke with `--plan`, assert the impl-menu bullets are emitted and `artdef_change_how` is not
  - add: `uchange: scn: --no-impl combined with --how` and `uchange: scn: --no-impl combined with --plan` - assert non-zero exit and stderr contains `--no-impl cannot be combined with --how or --plan`
  - update: rename `uchange: --specs creates specs folder and emits FD label` to `uchange: --specs creates specs folder`, drop the FD-bullet assertion (FD emission now requires `--plan`, not `--specs`); remove the redundant `uchange: without --specs and no specs folder, FD label not emitted` test (FD emission is covered by the updated default-branch tests)

### Implementation

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: `cmd_action_uchange` arg-parsing loop - add `--how` (sets `opt_how="1"`) and `--plan` (sets `opt_plan="1"`); leave `--no-impl` parsing in place
  - add: validation block after the `--branch` / `--no-branch` mutual-exclusion check - error `--no-impl cannot be combined with --how or --plan` when `opt_no_impl` is set together with `opt_how` or `opt_plan`
  - update: derivation block around line 714 - replace `[[ -z "$opt_no_impl" ]] && impl_maybe="1"` with `[[ -n "$opt_plan" ]] && impl_maybe="1"`; add `local how_maybe=""; [[ -n "$opt_how" ]] && how_maybe="1"`
  - update: `context_vars` associative array - replace `[no_impl]="$opt_no_impl"` with `[how_maybe]="$how_maybe"`
  - update: usage comment at the top of `cmd_action_uchange` (lines 565-566) - add `[--how]` and `[--plan]` to the documented signature
  - update: usage comment in the top-of-file header block (lines 36-37) - mirror the same signature update

- [x] update: [prompts/instr_uchange.md](../../../../../bin/prompts/instr_uchange.md)
  - update: replace the `(?no_impl)` gate on the `## How` bullet with `(?how_maybe)` to match the new positive context var

- [x] update: [templates/actions/uchange.yaml](../../../../../scripts/templates/actions/uchange.yaml)
  - update: `options:` line - insert `--how` and `--plan` into the comma-separated list, preserving the existing flag order

## Quick start

Opt into the implementation plan flow and the `## How` narrative explicitly:

- `uchange --how add user authentication` - emit base change request plus the `## How` section
- `uchange --plan add user authentication` - emit base change request plus the impl sections menu and auto-invoke `uimpl`
- `uchange --how --plan add user authentication` - emit both the `## How` section and the impl sections menu
- `uchange --no-impl ...` - retained as a backwards-compatible no-op; combining it with `--how` or `--plan` exits with `--no-impl cannot be combined with --how or --plan`
