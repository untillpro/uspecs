---
change_id: 2606122037-what-fault-detection-scenarios
type: feat
domains: [prod]
scope: [softeng]
breaking: true
---

# Change request: Fault signal in What and uchange planning options removal

## Why

`uchange` functional scenarios should make the expected `## What` behavior explicit for fault-oriented change requests. Without that scenario coverage, agents and tools can treat any generated `## What` section as proof that the fault is localized. For the same reason, `uchange` should not offer to author `## How` or an implementation plan at creation time: the `## What` may not be resolved yet, and planning belongs after the Engineer has reviewed it. `uimpl` is where the marker becomes actionable: planning must not start while the fault is unlocalized.

## What

### Unlocalized fault marker

Requirements for the unlocalized fault marker in `uchange`-generated fix-style change requests:

- The unlocalized fault marker is a `?` flowchart step annotated with `<-- fault: not yet localized`.
- If the agent can localize the fault -- identify the faulty mechanism, file, symbol, rule, or causal step and explain how it causes the symptom -- the generated `## What` flowchart must not contain the unlocalized fault marker.
- Otherwise, the generated `## What` flowchart must contain the unlocalized fault marker.
- Localization effort at `uchange` time is bounded to a quick static investigation: the agent may read and search the codebase, but must not run code or tests and must not attempt to reproduce the symptom. The investigation is capped at roughly 5 searches and 10 file reads; the agent stops earlier as soon as pinning the fault would require verification rather than reading. When either limit is hit without an evident fault, the marker is placed; deeper localization belongs to the `uimpl` gate below.

### Removal of --how and --plan from uchange

Requirements for the `uchange` option surface:

- `uchange` no longer accepts `--how` and `--plan`; it no longer authors `## How` or implementation-plan sections, while the rest of the change request shape (heading, optional Resolves, Why, What) is unchanged.
- `uchange` never invokes `uimpl` automatically; `## How` authoring and implementation planning happen in `uimpl`, which already authors `## How` when it is missing.
- `--no-impl` and `--no-self-review` are removed from `uchange` as well: the first existed only as a backwards-compatible no-op rejecting combination with the removed flags, the second only affected the `--plan` path.
- `uimpl` keeps its own `--plan` and `--no-self-review` options unchanged.

### Fault localization gate in uimpl

Requirements for the `uimpl` fault localization gate:

- The gate triggers only when the Change File has frontmatter `type: fix` and the unlocalized fault marker appears as a standalone line inside the `## What` section; marker text embedded in a prose line, outside the What section, or on other change types does not trigger the gate.
- When the gate triggers, `uimpl` does not author `## How` and does not produce planning sections; the gate is unconditional -- no option bypasses it.
- Instead, `uimpl` instructs the agent to localize the fault and to track localization efforts in `fault.md` in the Change Folder.
- When `fault.md` already exists, `uimpl` must instruct the agent to read it and build on the recorded efforts rather than restart the investigation.
- The `fault.md` format is up to the agent; the file persists across invocations and feeds subsequent localization attempts while the fault remains unresolved.
- If the agent localizes the fault, it replaces the `?` step in the `## What` flowchart with the concrete faulty step and re-invokes `uimpl` with the original arguments.
- If the agent cannot localize the fault, it updates `fault.md` with the efforts taken, informs the Engineer of those efforts, and stops processing.

## How

Decisions:

- Detect the gate condition by extending the existing single-pass pure-bash `change.md` scanner in `cmd_action_uimpl` (`bin/softeng.sh`) with a `## What`-section state flag and a full-line marker match, plus a frontmatter `type: fix` check via the shared `md_read_frontmatter_field` helper -- no fence tracking
- Place the gate as the first branch of the `uimpl` decision cascade, emitting a new prompt `instr_uimpl_fault.md` that renders the original invocation arguments for re-invocation and a conditional line to continue from an existing `fault.md`
- Encode the marker placement rules and the bounded static investigation (no execution, ~5 searches / 10 file reads, early-stop rule) in `artdef_change_what_fix.md` next to the existing marker notation
- Remove `--how`, `--plan`, `--no-impl`, and `--no-self-review` from `cmd_action_uchange` and `ACTION_OPTIONS[uchange]` (option lists render from `ACTION_OPTIONS` via `meta options`; `scripts/templates/actions/uchange.yaml` carries no option list and needs no change); drop the `(?how_requested)` How line and the impl-sections menu from `instr_uchange.md`

Out of scope:

- Changes to `uimpl`'s own `--plan` and `--no-self-review` semantics
- A prescribed `fault.md` format or artifact definition (format is up to the agent)
- Post-localization lifecycle of `fault.md` (left open by clarification)

References:

- [action implementations and uimpl decision cascade](../../../../../bin/softeng.sh)
- [uchange instruction template](../../../../../bin/prompts/instr_uchange.md)
- [fix-style What artifact definition](../../../../../bin/prompts/artdef_change_what_fix.md)
- [uchange dispatch manifest](../../../../../scripts/templates/actions/uchange.yaml)
- [uchange feature spec](../../../../specs/prod/softeng/uchange.feature)
- [uimpl feature spec](../../../../specs/prod/softeng/uimpl.feature)
- [uchange system tests](../../../../../tests/sys/softeng.sh-action-uchange.bats)
- [uimpl system tests](../../../../../tests/sys/softeng.sh-action-uimpl.bats)

## Functional design

- [x] update: [softeng/uchange.feature](../../../../specs/prod/softeng/uchange.feature)
  - remove: "--how option forces How section creation" scenario
  - remove: "Rule: Chaining to implementation" entirely: drop the "--no-impl option is a backwards-compatible no-op" and "--plan option" scenarios, relocate the surviving "--specs option" and self-review scenarios to the feature top level
  - update: "uchange without --plan does not chain self-review" scenario outline -> "uchange does not chain self-review"; drop the "with --how option" example row
  - remove: "--no-impl combined with --how or --plan" scenario outline from "Rule: Edge cases"
  - add: scenario in "Rule: Edge cases" asserting the removed options --how, --plan, --no-impl, --no-self-review are rejected as unknown arguments and change request is not created
  - add: rule for fix-style What fault localization signal with scenarios:
    - flowchart contains the unlocalized fault marker (a `?` step annotated `<-- fault: not yet localized`) when the agent cannot localize the fault within the bounded static investigation
    - flowchart names the fault on a concrete step and contains no marker when the agent localizes the fault
    - agent instructions bound the uchange-time investigation: read/search only, no code or test execution, no symptom reproduction, capped at ~5 searches and 10 file reads with early stop when verification would be required

- [x] update: [softeng/uimpl.feature](../../../../specs/prod/softeng/uimpl.feature)
  - add: rule for the fault localization gate with scenarios:
    - gate triggers only when change.md frontmatter is `type: fix` and the marker appears as a standalone line inside the What section; marker text elsewhere (embedded in prose, outside What, other change types) does not trigger
    - when gated, uimpl emits no How section and no planning sections regardless of options (--plan included)
    - gated instructions tell the agent to localize the fault and track efforts in fault.md in the Change Folder
    - when fault.md already exists, instructions tell the agent to read it and build on recorded efforts rather than restart
    - on successful localization the agent replaces the `?` step with the concrete faulty step and re-invokes uimpl with the original arguments
    - on failure the agent updates fault.md with the efforts taken, informs the Engineer of those efforts, and stops processing
  - update: "How section creation when missing" scenario outline -> note the fault localization gate precedes How authoring for gated change files

## Construction

### Tests

- [x] update: [sys/softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - remove: tests "--no-impl option is a backwards-compatible no-op", "--how option forces How section creation", "--plan option", "--plan chains self-review --type specs --stage A -b 4", "--plan --no-self-review suppresses the chain", "--no-self-review without --plan is accepted as a no-op", and both "--no-impl combined with --how or --plan" tests
  - update: "uchange without --plan does not chain self-review: default, --how, fetchable" test -> rename per the renamed scenario; drop the --how invocation
  - add: test for scenario "Removed planning options are rejected": each of --how, --plan, --no-impl, --no-self-review fails with "Unknown argument" and no Change Folder is created

- [x] update: [sys/softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
  - add: fault localization gate tests:
    - `type: fix` + marker as a standalone line inside the What section emits the fault prompt with no How and no planning sections
    - negatives: marker embedded in prose, marker outside What, `type: feat` -> gate does not trigger, normal cascade proceeds
    - --plan does not bypass the gate
    - existing fault.md in the Change Folder adds the continue-from-fault.md line to the prompt; absent fault.md omits it
    - the prompt renders the re-invocation line with the original invocation arguments

### Implementation

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: `ACTION_OPTIONS[uchange]` -- drop `--how`, `--plan`, `--no-impl`, `--no-self-review` (the meta-options consistency test enforces table/parser parity)
  - update: `cmd_action_uchange` -- remove the four option case arms and their locals, the `--no-impl` combination validation, the `plan_requested`/`how_requested` derivations, and the chain-self-review block; drop `how_requested`, `domains_maybe`, `fd_maybe`, `prov_maybe`, `td_maybe`, `constr_maybe`, and the chain/self-review vars from `context_vars`
  - update: `cmd_action_uimpl` -- extend the single-pass `change.md` scan with a `## What`-section state flag to detect the marker `? <-- fault: not yet localized` as a standalone line inside the What section, reading frontmatter `type: fix` via `md_read_frontmatter_field`; add the gate as the first branch of the decision cascade, emitting `instr_uimpl_fault` with the Change Folder, a fault.md-exists flag, and the original invocation arguments

- [x] update: [prompts/instr_uchange.md](../../../../../bin/prompts/instr_uchange.md)
  - remove: the `How, see @artdef_change_how (?how_requested)` line, the `@include_impl_sections` reference, and the `@include_chain_self_review` reference (the include files stay -- uimpl prompts still use them)

- [x] create: [prompts/instr_uimpl_fault.md](../../../../../bin/prompts/instr_uimpl_fault.md)
  - Gated instruction emitted when the fault localization gate triggers
  - Instructs the agent to localize the fault and track efforts in `fault.md` in the Change Folder
  - Conditional line (fault.md exists): read it and build on the recorded efforts rather than restart
  - On success: replace the `?` step in the What flowchart with the concrete faulty step and re-invoke uimpl with the original arguments (rendered)
  - On failure: update `fault.md` with the efforts taken, inform the Engineer of those efforts, and stop processing

- [x] update: [prompts/artdef_change_what_fix.md](../../../../../bin/prompts/artdef_change_what_fix.md)
  - add: marker placement rules -- marker present when the fault is not localized, absent when a concrete faulty step is named
  - add: bounded static investigation rules -- read/search only, no code or test execution, no symptom reproduction, capped at ~5 searches and 10 file reads, early stop when verification would be required

- [x] update: [uspecs-concepts/SKILL.md](../../../../../.claude/skills/uspecs-concepts/SKILL.md)
  - update: change.md artifact line -- drop the stale "(plus How when created with --no-impl)" qualifier
  - update: uchange action list entry -- drop "optionally chain into uimpl"

## Quick start

For fix-type change requests:

1. `uchange --type fix ...` -- the agent performs a quick static investigation (read/search only); when the fault cannot be pinned, the What flowchart carries `? <-- fault: not yet localized`
2. `uimpl` -- while the marker is present, planning is gated: the agent investigates the fault, tracking efforts in `fault.md` in the Change Folder
3. On localization the agent replaces the `?` step with the concrete faulty step and re-invokes `uimpl`; planning then proceeds as usual

Removed from `uchange` (breaking): `--how`, `--plan`, `--no-impl`, `--no-self-review`. How authoring and planning now happen exclusively in `uimpl`.
