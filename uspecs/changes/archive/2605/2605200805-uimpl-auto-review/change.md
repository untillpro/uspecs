---
registered_at: 2026-05-19T18:07:24Z
change_id: 2605191807-uimpl-auto-review
type: feat
scope: softeng
baseline: db031d580c2c2f963c4e127053a622d020c57c33
archived_at: 2026-05-20T08:05:17Z
---

# Change request: Automatic self-review after uimpl todos

## Why

After uimpl processes a batch of unchecked todo items, there is no automatic verification pass before the AI Agent stops or hands control back to the Engineer. Issues such as mismatches with the change request, duplicated logic in construction work, or spec scope drift go unnoticed unless a human review checkpoint exists. An automatic self-review hand-off raises baseline quality on every uimpl cycle without requiring Engineer intervention.

## What

- After uimpl finishes implementing unchecked todo items for a section, the AI Agent automatically performs self-review passes
- --no-self-review flag to disable automatic self-reviews for a uimpl invocation
- Self-review types: `specs`, `construction`
- `specs`:
  - All todo items are not in Construction section
  - Stage A:
    - Scope1: Inconsistencies with the change request, scope drift, missing details, and other issues related to the changes in the specifications
    - Scope2: DRY -- avoid writing the same thing twice across specs
- `construction`:
  - Some todo items are in Construction section
  - stage A: same as specs A.1
  - stage B: DRY, SOLID
  - stage C (optional): concurrency issues
- The self-review hand-off is a pure prompt dispatch on the softeng side; it does not inspect git state or validate review outcomes.
- Within a stage, if the Agent finds issues, it fixes them inline and advances to the next stage; a stage is never re-run
- At the end Agent reports results of the self-review

## How

- A new top-level softeng command `self-review` (not under `action`)
  - Usage: `bash bin/softeng.sh self-review --type X --stage Y [--concurrency]`
  - Stage chaining: the response of each stage instructs the Agent to perform the review for that stage and then invoke the next stage (`--stage A` chains to `--stage B`, etc.); the final stage instructs the Agent to report results
  - `--concurrency` is decided at the uimpl -> self-review boundary: when Construction todos were completed, the uimpl emit instructs the Agent to evaluate whether the implemented changes touch concurrency-sensitive code paths and pass the result back to softeng by setting or omitting `--concurrency` on the Stage A call; the flag is then a plain input that propagates unchanged through Stage A -> B -> C and enables the optional construction Stage C

## Functional design

- [x] update: [softeng/uimpl.feature](../../../../specs/prod/softeng/uimpl.feature)
  - add: scenario outline for auto-invocation of self-review after todos complete, with examples covering `--type` selection by completed section (specs for Functional/Technical/Domain/Provisioning, construction for Construction) and suppression via `--no-self-review`
  - add: scenario for Construction-only concurrency evaluation instruction; AI Agent evaluates concurrency relevance and includes `--concurrency` on the self-review invocation when applicable

- [x] create: [softeng/self-review.feature](../../../../specs/prod/softeng/self-review.feature)
  - Feature specification for the new top-level softeng self-review command with scenarios covering: stage chaining (A -> B -> C with chain hand-off in the prompt), per-stage inline fix and advance, `--concurrency` as an input flag (decided by uimpl) that propagates through the chain and gates Stage C, and end-of-chain results reporting

## Technical design

- [x] update: [softeng/arch.md](../../../../specs/prod/softeng/arch.md)
  - update: describe how self-review happens, provide ascii flow diag

## Construction

### Tests

- [x] create: [softeng.sh-self-review.bats](../../../../../tests/sys/softeng.sh-self-review.bats)
  - System tests for the new top-level `self-review` command
  - Coverage:
    - dispatch: `bash bin/softeng.sh self-review --type specs --stage A` emits the Stage A specs prompt with chain instruction to report results
    - dispatch: `--type construction --stage A` emits Stage A prompt with chain instruction to invoke `--stage B` (propagating `--concurrency` when set)
    - dispatch: `--type construction --stage B` without `--concurrency` chains to report results; with `--concurrency` chains to `--stage C --concurrency`
    - dispatch: `--type construction --stage C --concurrency` emits Stage C prompt with chain to report results
    - validation: unknown `--type`, unknown `--stage`, missing required arguments produce errors
    - validation: `--concurrency` only accepted with `--type construction`

- [x] update: [softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
  - add: cases that completing Construction todos via uimpl emits the chained `self-review --type construction --stage A` instruction
  - add: cases that completing only specs-side todos emits the chained `self-review --type specs --stage A` instruction
  - add: case that `--no-self-review` suppresses the chain instruction
  - add: case that Construction-todos emit also includes the concurrency-evaluation instruction

### Source

- [x] create: [prompts/instr_self_review_specs_a.md](../../../../../bin/prompts/instr_self_review_specs_a.md)
  - Stage A prompt for `--type specs`: instructs the Agent to review specs for consistency with the change request and DRY across specs, fix issues inline, and inline-report results to the Engineer (terminal stage)

- [x] create: [prompts/instr_self_review_construction_a.md](../../../../../bin/prompts/instr_self_review_construction_a.md)
  - Stage A prompt for `--type construction`: instructs the Agent to review construction artifacts for consistency with the change request, fix issues inline, and then invoke `bash bin/softeng.sh self-review --type construction --stage B` (propagating `--concurrency` when it was set on this Stage A invocation)

- [x] create: [prompts/instr_self_review_construction_b.md](../../../../../bin/prompts/instr_self_review_construction_b.md)
  - Stage B prompt for `--type construction`: instructs the Agent to review construction artifacts for DRY and SOLID, fix issues inline, and then either invoke `bash bin/softeng.sh self-review --type construction --stage C --concurrency` (when `--concurrency` was set on this Stage B invocation) or inline-report results to the Engineer (terminal)

- [x] create: [prompts/instr_self_review_construction_c.md](../../../../../bin/prompts/instr_self_review_construction_c.md)
  - Stage C prompt for `--type construction`: instructs the Agent to review construction artifacts for concurrency issues, fix issues inline, and inline-report results to the Engineer (terminal stage)

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - add: `cmd_self_review` that parses `--type {specs|construction} --stage {A|B|C} [--concurrency]`, validates the combination (Stage C requires `--type construction`, `--concurrency` requires `--type construction`), selects the matching prompt template, and emits it via `emit_prompt`
  - add: dispatch branch in `main` for top-level command `self-review` calling `cmd_self_review`
  - update: `cmd_action_uimpl` to accept `--no-self-review` and to append a chained self-review instruction at the end of the `instr_uimpl_todos` emit when at least one to-do item was processed, unless suppressed; choose `--type` based on whether any completed todos were in the Construction section; for the Construction case, also include an explicit instruction telling the Agent to evaluate concurrency relevance and pass `--concurrency` accordingly
  - update: usage comment block at the top of the file to list the new `self-review` command and the new `--no-self-review` flag on `uimpl`

- [x] update: [prompts/instr_uimpl_todos.md](../../../../../bin/prompts/instr_uimpl_todos.md)
  - add: trailing chain section (conditional on a `chain_self_review` flag) that tells the Agent to invoke `bash bin/softeng.sh self-review --type ${self_review_type} --stage A` after checking off all to-do items; when `chain_self_review_construction` is set, include the concurrency-evaluation instruction directing the Agent to add `--concurrency` to the invocation when applicable

## Quick start

New behavior introduced by this change:

- After `uimpl` finishes processing unchecked to-do items, the AI Agent automatically runs a self-review pass scoped to what was just implemented.
- Engineers can opt out per invocation with `bash bin/softeng.sh action uimpl --no-self-review`.
- For Construction work, the Agent is instructed to evaluate whether the changes touch concurrency-sensitive code paths and, when so, extend the self-review with a concurrency stage.
