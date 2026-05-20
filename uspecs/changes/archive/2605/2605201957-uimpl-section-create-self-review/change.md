---
registered_at: 2026-05-20T17:16:05Z
change_id: 2605201716-uimpl-section-create-self-review
type: feat
scope: softeng
baseline: 8af41df2c1355e7d050894161d133b12bc4b974e
archived_at: 2026-05-20T19:57:13Z
---

# Change request: Self-review after authoring plan sections in uimpl and uchange

## Why

`uimpl` already auto-invokes a self-review after the AI Agent completes unchecked to-do items, but the cascade that appends new sections (Domain specifications, Functional design, Provisioning and configuration, Technical design, Construction) to the Implementation Plan File runs without any review. The same gap exists in `uchange --plan`, which authors the first implementation section directly inside `change.md`. Section bullets reference spec files to create or update, so misalignments with the change request (scope drift, inconsistencies, duplication across plan entries) can accumulate undetected until later stages.

The existing post-todos chain also has no retry mechanism: a single review pass that fixes issues inline may itself introduce follow-on issues that go unverified.

## What

Extend the auto-review trigger in the softeng domain so that every cycle which authors a new plan section (in either `uimpl` or `uchange --plan`) chains a specs-scoped self-review pass, and add a bounded retry budget for specs reviews so a pass that finds and fixes issues can be repeated until stable or the budget is exhausted.

- Section-creation cycles in `uimpl` chain `self-review --type specs --stage A` after the section is appended, scoped to the newly added bullets

- `uchange` invocations with `--plan` chain `self-review --type specs --stage A` after the change request and its plan section are authored, scoped to the newly added bullets

- The chained review uses `--type specs` regardless of which section was created (including Construction), because no construction artifacts exist yet at section-creation time

- A new `-b N` option on `self-review --type specs` carries a retry budget; the script decrements it script-side and renders the next-invocation command into the prompt, so the Agent re-invokes the same stage with `-b (N-1)` only if new issues were detected during the current pass

- `-b` is rejected for `--type construction`, mirroring how `--concurrency` is rejected for `--type specs`

- A new `--no-self-review` flag on `uchange` suppresses the chain; the existing `--no-self-review` flag on `uimpl` continues to suppress both the section-creation chain and the post-todos chain

- The auto-chains from `uimpl` and `uchange --plan` attach a default `-b N` (value selected in `decisions.md`)

## How

Decisions:

- Add a shared include `bin/prompts/include_chain_self_review.md` containing the chain instructions (announce the review and invoke `bash bin/softeng.sh self-review --type ${self_review_type} --stage A -b ${self_review_budget}`); reference it via `@include_chain_self_review` from `instr_uimpl.md`, `instr_uimpl_todos.md`, and `instr_uchange.md` so the three callers stay in lockstep without copy-paste

- Gate the chain script-side, not template-side: each caller computes `chain_self_review` once and the shared include is wrapped in a single `(?chain_self_review)` block at every host site. Concretely:
  - `cmd_action_uimpl`: `chain_self_review="1"` when `!opt_no_self_review` and a section is being appended (section-creation subcase) or all unchecked to-dos were completed (existing post-todos subcase)
  - `cmd_action_uchange`: `chain_self_review="1"` when `!opt_no_self_review` and `impl_maybe` is set (i.e. `--plan` was passed). Why/What-only, `--how`-only, and `--fetchable`-only invocations do not chain because they produce no plan bullets to review

- Set `self_review_type=specs` in both callers for the section/plan-bullet chains regardless of which section was authored; no `--concurrency` evaluation is wired here because construction artifacts do not yet exist at section-creation time

- Add `-b N` parsing and validation to `cmd_self_review` (`bin/softeng.sh`): parse `-b N`, validate `-b requires --type specs` and `N >= 0` (non-negative integer; reject negatives as a parse error). Pass `next_budget=N-1` into the review context vars only when `N > 0`; set the `budget` gate (the variable that triggers the `(?budget)` block in the prompt) only when `N > 0`. When `N == 0`, accept the invocation but suppress the retry block - the chain terminates cleanly at `-b 0` with the unconditional "report results" tail. When `-b` is omitted entirely, both vars are unset and the same terminal branch fires

- Make `bin/prompts/instr_self_review_specs_a.md` conditional on `(?budget)`: the retry instruction "If new issues were detected during this review, re-invoke this stage: `bash bin/softeng.sh self-review --type specs --stage A -b ${next_budget}`" renders only when `budget` is set; the terminal "report results" instruction renders unconditionally as the fallback after a clean pass (or when `budget` is absent). Remove the existing "Do not re-run this stage" rule entirely - the budget mechanism is the sole termination control (self-terminating at the zero-issue fixed point or at `-b 0`)

- Broaden the review subject in `bin/prompts/instr_self_review_specs_a.md` from "specs that were just changed (or added) by `uimpl`" to "specs and/or to-do items that were just changed (or added) by `uimpl` or `uchange`" so a single Stage A prompt serves all three triggers (post-todos, section-creation in `uimpl`, plan-creation in `uchange --plan`)

- Add `--no-self-review` parsing to `cmd_action_uchange`, mirroring the flag on `cmd_action_uimpl`; document it in the usage comment block and in `uchange.feature`

- Update `uspecs/specs/prod/softeng/uimpl.feature` to add a Scenario Outline covering section-creation auto-invocation (one row per section name) plus a `--no-self-review` suppression row, parallel to the existing todos scenario

- Update `uspecs/specs/prod/softeng/uchange.feature` to add scenarios for `--plan` chaining the specs review with the default budget, and for `--no-self-review` suppressing the chain

- Update `uspecs/specs/prod/softeng/self-review.feature` with scenarios for `-b N` propagation, decrement to `-b 0`, terminal behavior at `-b 0` / absent, and rejection of `-b` with `--type construction`

- Add `[softeng_sh]="$_CTX_SCRIPT_DIR/softeng.sh"` to the context-vars maps in `cmd_action_uimpl`, `cmd_action_uchange`, and `cmd_self_review` (both specs and construction branches), mirroring the existing pattern in `cmd_action_usync`; reference it as `bash ${softeng_sh}` in every review template that instructs the agent to re-run `softeng.sh`: the new `include_chain_self_review.md`, the `(?budget)` retry block in `instr_self_review_specs_a.md`, the Stage B advance lines in `instr_self_review_construction_a.md`, and the Stage C advance line in `instr_self_review_construction_b.md`. This makes chained invocations work when the script is run from a plugin install path rather than the repo-relative `bin/`

Out of scope:

- Introducing new self-review types, stages, or concurrency handling beyond `-b N` for specs
- Running self-review on `uchange` invocations without `--plan` (no plan bullets to review)
- Running self-review on `uimpl` cycles that only emit the "plan completed" notice (no section appended in this cycle)
- A budget mechanism for `--type construction` (deferred; the cross-stage A->B->C interaction warrants its own change)
- Changing the behavior of the existing post-todos chain other than attaching the same default `-b N`

References:

- [uimpl action implementation](../../../../../bin/softeng.sh)
- [instr_uimpl prompt template](../../../../../bin/prompts/instr_uimpl.md)
- [instr_uimpl_todos prompt template](../../../../../bin/prompts/instr_uimpl_todos.md)
- [instr_uchange prompt template](../../../../../bin/prompts/instr_uchange.md)
- [Stage A specs review prompt](../../../../../bin/prompts/instr_self_review_specs_a.md)
- [Stage A construction review prompt](../../../../../bin/prompts/instr_self_review_construction_a.md)
- [Stage B construction review prompt](../../../../../bin/prompts/instr_self_review_construction_b.md)
- [uimpl feature spec](../../../../../uspecs/specs/prod/softeng/uimpl.feature)
- [uchange feature spec](../../../../../uspecs/specs/prod/softeng/uchange.feature)
- [self-review feature spec](../../../../../uspecs/specs/prod/softeng/self-review.feature)
- [uimpl system tests](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
- [uchange system tests](../../../../../tests/sys/softeng.sh-action-uchange.bats)
- [self-review system tests](../../../../../tests/sys/softeng.sh-self-review.bats)
- [previous change introducing the post-todos chain](../../../archive/2605/2605200805-uimpl-auto-review/change.md)

## Functional design

- [x] update: [softeng/uimpl.feature](../../../../specs/prod/softeng/uimpl.feature)
  - add: Scenario Outline "Auto-invoke self-review after section creation" parallel to the existing "Auto-invoke self-review after todos", with one row per section name (Domain specifications, Functional design specifications, Provisioning and configuration, Technical design specifications, Construction) asserting that `uimpl` chains `self-review --type specs --stage A -b 4`, and one row with `--no-self-review` asserting suppression
  - update: existing "Auto-invoke self-review after todos" Examples table - append `-b 4` to the chained invocation in the rows that target `--type specs`; leave the Construction row (`--type construction`) unchanged because `-b` is rejected for construction
  - add: scenario asserting that `uimpl` does NOT chain `self-review` on the "plan completed" notice cycle (no section appended, no unchecked to-dos)

- [x] update: [softeng/uchange.feature](../../../../specs/prod/softeng/uchange.feature)
  - add: scenario "uchange --plan chains specs self-review" asserting that `uchange --plan` emits an invocation of `self-review --type specs --stage A -b 4` after authoring the plan section
  - add: scenario "uchange --no-self-review suppresses the chain" asserting that `uchange --plan --no-self-review` emits no `self-review` invocation
  - add: scenario "uchange without --plan does not chain self-review" asserting that default, `--how`, and `--fetchable` invocations emit no `self-review` invocation

- [x] update: [softeng/self-review.feature](../../../../specs/prod/softeng/self-review.feature)
  - update: comment block (lines 4-8) - extend the documented usage to `bash bin/softeng.sh self-review --type {specs|construction} --stage {A|B|C} [--concurrency] [-b N]` and note that `-b N` applies only to `--type specs`
  - update: existing "Stage prompt drives review and chain hand-off" Examples table - broaden the specs A `scope` column from "consistency with change request and DRY across specs" to "consistency with change request and DRY across specs and/or to-do items"
  - update: existing "Inline fix and advance" scenario - replace "advances to the next chained step without re-running the stage" with wording that allows budget-controlled re-invocation of the same specs stage when new issues were detected during the pass
  - add: Scenario Outline "Specs review retry budget propagation" with rows for `-b 4 -> retry block renders -b 3`, `-b 1 -> retry block renders -b 0`, and `-b 0 -> no retry block, terminal report only`
  - add: scenario "Retry block fires only when new issues were detected during the pass" asserting the conditional trigger wording in the prompt
  - add: scenario "-b is rejected for --type construction" asserting that `self-review --type construction --stage A -b 1` errors out with a message symmetric to the existing "--concurrency requires --type construction" rule
  - add: scenario "-b rejects negative values" asserting that `self-review --type specs --stage A -b -1` errors out

## Construction

### Tests

- [x] update: [softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
  - add: test asserting that a section-creation cycle (no unchecked to-dos, missing section) renders `chain_self_review="1"`, `self_review_type="specs"`, and `self_review_budget="4"` into the rendered prompt context, so the rendered chained invocation reads `bash ${softeng_sh} self-review --type specs --stage A -b 4`
  - add: test asserting that `uimpl --no-self-review` on a section-creation cycle does NOT render `chain_self_review` (and therefore emits no chained invocation)
  - add: test asserting that a "plan completed" cycle (no unchecked to-dos, all sections present) does NOT render `chain_self_review`
  - update: existing post-todos chain tests to assert that the rendered chained invocation now ends with `-b 4` when `self_review_type="specs"`, and stays unchanged (no `-b`) when `self_review_type="construction"`

- [x] update: [softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - add: test asserting that `uchange --plan` renders `chain_self_review="1"`, `self_review_type="specs"`, and `self_review_budget="4"` so the rendered chained invocation reads `bash ${softeng_sh} self-review --type specs --stage A -b 4`
  - add: test asserting that `uchange --plan --no-self-review` does NOT render `chain_self_review`
  - add: test asserting that `uchange` without `--plan` (default, `--how`, `--fetchable`) does NOT render `chain_self_review`
  - add: test asserting that `uchange --no-self-review` without `--plan` is accepted as a no-op (flag parses, no chain to suppress, no error)

- [x] update: [softeng.sh-self-review.bats](../../../../../tests/sys/softeng.sh-self-review.bats)
  - add: test asserting that `self-review --type specs --stage A -b 4` renders `budget=4` and `next_budget=3` into the prompt
  - add: test asserting that `self-review --type specs --stage A -b 1` renders `budget=1` and `next_budget=0`
  - add: test asserting that `self-review --type specs --stage A -b 0` accepts the invocation but renders neither `budget` nor `next_budget` (no retry block)
  - add: test asserting that `self-review --type specs --stage A` (no `-b`) renders neither `budget` nor `next_budget`
  - add: test asserting that `self-review --type construction --stage A -b 1` exits non-zero with an error mentioning `-b requires --type specs`
  - add: test asserting that `self-review --type specs --stage A -b -1` exits non-zero with an error indicating `-b` requires a non-negative integer
  - add: test asserting that every rendered review-template invocation uses `${softeng_sh}` (the absolute path), not a hardcoded `bin/softeng.sh`

- review

### Prompts

- [x] create: [prompts/include_chain_self_review.md](../../../../../bin/prompts/include_chain_self_review.md)
  - Purpose: shared instruction block injected via `@include_chain_self_review` from `instr_uimpl.md`, `instr_uimpl_todos.md`, and `instr_uchange.md` so the three callers stay in lockstep
  - Content: wrapped in `(?chain_self_review)`; informs the user a self-review pass will now run scoped to the work just completed; the construction concurrency-eval line preserved under `(?chain_self_review_construction)`; invokes `bash ${softeng_sh} self-review --type ${self_review_type} --stage A` with a trailing `-b ${self_review_budget}` segment gated on `(?self_review_budget)`, so the budget renders for specs chains (where the callers set `self_review_budget=4`) and is omitted for the construction post-todos chain (where `-b` is rejected by `self-review`)

- [x] update: [prompts/instr_uimpl.md](../../../../../bin/prompts/instr_uimpl.md)
  - add: a trailing `@include_chain_self_review` reference after the existing `@include_impl_sections` line, gated on `(?chain_self_review)`, so a section-creation cycle automatically chains the specs review

- [x] update: [prompts/instr_uimpl_todos.md](../../../../../bin/prompts/instr_uimpl_todos.md)
  - replace: the inline `(?chain_self_review)` block (lines 14-17) with `@include_chain_self_review` so the post-todos chain shares the include with the section-creation chain and the uchange `--plan` chain

- [x] update: [prompts/instr_uchange.md](../../../../../bin/prompts/instr_uchange.md)
  - add: a trailing `@include_chain_self_review` reference under `(?chain_self_review)` so `uchange --plan` chains the specs review after authoring the plan section

- [x] update: [prompts/instr_self_review_specs_a.md](../../../../../bin/prompts/instr_self_review_specs_a.md)
  - update: opening sentence from "specs that were just changed (or added) by `uimpl`" to "specs and/or to-do items that were just changed (or added) by `uimpl` or `uchange`" so a single Stage A prompt serves all three triggers
  - remove: the existing "Do not re-run this stage" rule entirely
  - add: a `(?budget)` block instructing the agent, when new issues were detected during this review, to re-invoke the stage as `bash ${softeng_sh} self-review --type specs --stage A -b ${next_budget}`; the unconditional "report results" instruction remains as the terminal step

- [x] update: [prompts/instr_self_review_construction_a.md](../../../../../bin/prompts/instr_self_review_construction_a.md)
  - replace: the hardcoded `bash bin/softeng.sh self-review --type construction --stage B ...` advance line(s) with `bash ${softeng_sh} self-review --type construction --stage B ...` so the chain works when the script is invoked from a plugin install path

- [x] update: [prompts/instr_self_review_construction_b.md](../../../../../bin/prompts/instr_self_review_construction_b.md)
  - replace: the hardcoded `bash bin/softeng.sh self-review --type construction --stage C ...` advance line with `bash ${softeng_sh} self-review --type construction --stage C ...`

### Script

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: `cmd_action_uimpl` to compute `chain_self_review="1"` and `self_review_type` in the section-creation branch (in addition to the existing post-todos branch); set `self_review_type="specs"` for section-creation regardless of which section was authored; set `self_review_budget="4"` whenever `self_review_type="specs"` (i.e. for specs chains only, not for the construction post-todos chain); add `[chain_self_review]`, `[self_review_type]`, `[self_review_budget]` (only when set), and `[softeng_sh]="$_CTX_SCRIPT_DIR/softeng.sh"` to the context-vars map in the section-creation branch
  - update: `cmd_action_uimpl` post-todos branch to set `self_review_budget="4"` only when `self_review_type="specs"` (leave it unset for the construction sub-branch so the include omits the `-b` segment); add `[self_review_budget]` (when set) and `[softeng_sh]="$_CTX_SCRIPT_DIR/softeng.sh"` to the context-vars map
  - update: `cmd_action_uchange` to parse a new `--no-self-review` flag and document it in the usage comment block above the function; on the `--plan` branch (`impl_maybe="1"`), set `chain_self_review="1"`, `self_review_type="specs"`, `self_review_budget="4"`, and add `[chain_self_review]`, `[self_review_type]`, `[self_review_budget]`, `[softeng_sh]` to the context-vars map; suppress `chain_self_review` (and therefore the related vars) when `--no-self-review` is passed; on non-`--plan` branches, `--no-self-review` is accepted as a no-op (nothing to suppress)
  - update: `cmd_self_review` to parse `-b N`; validate that `-b` requires `--type specs` (error message: `-b requires --type specs`); validate that `N >= 0` (reject negatives with a parse error); when `N > 0`, set `budget="$N"` and `next_budget="$((N-1))"` in the context-vars map; when `N == 0` or `-b` is omitted, leave both unset; add `[softeng_sh]="$_CTX_SCRIPT_DIR/softeng.sh"` to the context-vars map in both the specs and construction branches

## Quick start

`uimpl` and `uchange --plan` now automatically chain a specs self-review pass with a retry budget of 4 after authoring a plan section:

- After `uimpl` appends Domain / Functional design / Provisioning / Technical design / Construction sections, it runs `softeng self-review --type specs --stage A -b 4`. The section-creation chain always uses `--type specs` (including when the appended section is Construction), because no construction artifacts exist yet at section-creation time
- After `uchange --plan` authors the first implementation section, it runs the same `--type specs -b 4` pass
- Pass `--no-self-review` to either action to suppress the chain
- The existing post-todos chain in `uimpl` is unchanged for the Construction case (still `--type construction` with no `-b`, because `-b` is rejected for construction); specs post-todos chains now carry `-b 4`
- `self-review --type specs` accepts a new `-b N` retry budget: if new issues are detected during the pass, the prompt instructs re-invocation with `-b (N-1)`; the chain terminates when a pass finds no new issues or when `-b 0` is reached
