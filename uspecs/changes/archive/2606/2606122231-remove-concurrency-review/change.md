---
change_id: 2606122155-remove-concurrency-review
type: refactor
domains: [prod]
scope: [softeng]
breaking: true
---

# Change request: Remove concurrency review from the construction self-review chain

## Why

The optional `--concurrency` flag and Stage C of the construction self-review chain add a rarely-used branch that complicates the review workflow and the supporting prompts. Removing it simplifies the chain and the tooling without affecting the routine review path.

## What

Simplify the construction self-review chain in the softeng domain by removing the concurrency branch:

- Drop the `--concurrency` flag from `self-review --type construction` (Stages A and B) and remove the concurrency-only Stage C entirely.
- Stop evaluating whether completed changes touch concurrency-sensitive code paths in the self-review dispatcher prompt.
- The default Stages A and B construction self-review behavior is preserved unchanged; only the optional concurrency branch is removed.

## How

Decisions:

- Remove the `--concurrency` flag from `cmd_self_review` in `bin/softeng.sh`, including its parsing, validation, and propagation into the prompt context map.
- Delete the concurrency-only Stage C prompt and simplify the Stage A/B prompts by dropping the `(?concurrency)` / `(?!concurrency)` conditional lines so Stage B becomes the terminal stage of the construction chain.
- Drop the silent concurrency-evaluation bullet from the chain dispatcher prompt so the chain never asks the agent to consider passing `--concurrency`.
- Update the softeng architecture diagram and the affected functional design features to reflect a two-stage construction self-review chain with no concurrency branch.

Out of scope:

- The specs self-review chain and the construction Stage A/B review behavior itself.
- Introducing any replacement check for concurrency-sensitive code paths.

References:

- [self-review dispatch and flag handling](../../../../../bin/softeng.sh)
- [chain self-review dispatcher prompt](../../../../../bin/prompts/include_chain_self_review.md)
- [construction Stage A prompt](../../../../../bin/prompts/instr_self_review_construction_a.md)
- [construction Stage B prompt](../../../../../bin/prompts/instr_self_review_construction_b.md)
- [construction Stage C prompt (to delete)](../../../../../bin/prompts/instr_self_review_construction_c.md)
- [softeng architecture diagram](../../../../../uspecs/specs/prod/softeng/arch.md)
- [self-review functional design](../../../../../uspecs/specs/prod/softeng/self-review.feature)
- [uimpl functional design](../../../../../uspecs/specs/prod/softeng/uimpl.feature)
- [self-review system tests](../../../../../tests/sys/softeng.sh-self-review.bats)
- [uimpl system tests](../../../../../tests/sys/softeng.sh-action-uimpl.bats)

## Functional design

- [x] update: [self-review.feature](../../../../specs/prod/softeng/self-review.feature)
  - update: usage comment to remove `[--concurrency]` from the documented `self-review` invocation
  - remove: the `--concurrency` input-flag explanation comment that references `uimpl`
  - update: "Stage prompt drives review and chain hand-off" scenario outline to drop the construction Stage C row and remove `--concurrency` propagation phrasing from the construction Stage A and Stage B `next` cells

- [x] update: [uimpl.feature](../../../../specs/prod/softeng/uimpl.feature)
  - remove: "Construction todos: AI Agent evaluates concurrency" scenario

## Technical design

- [x] update: [softeng/arch.md](../../../../specs/prod/softeng/arch.md)
  - update: self-review chain diagram to drop the "evaluate concurrency" branch, the `[--concurrency]` annotations on Stage A/B, and the Stage C subtree
  - update: Stage B key-artifact note to mark it as terminal (drop the "unless `--concurrency`" qualifier)
  - remove: Stage C, concurrency key-artifact entry pointing to `bin/prompts/instr_self_review_construction_c.md`

## Construction

### Tests

- [x] update: [sys/softeng.sh-self-review.bats](../../../../../tests/sys/softeng.sh-self-review.bats)
  - update: "construction Stage A chains to Stage B (propagating --concurrency when set)" test to drop the `--concurrency` propagation case and rename to reflect the single A→B path
  - update: "construction Stage B without --concurrency chains to report" test to drop the "without --concurrency" qualifier from its name
  - remove: "construction Stage B with --concurrency chains to Stage C --concurrency" test
  - remove: "construction Stage C emits Stage C prompt and reports results" test
  - remove: "--concurrency rejected with --type specs" test
  - update: "specs has only Stage A (Stage B/C rejected)" test to reflect that `--stage C` is now globally rejected
  - update: stage argument error-message assertions and trailing "Construction Stage B with --concurrency: advance to Stage C must use abs path" block to drop the `--concurrency`/Stage C case
  - add: test asserting `--concurrency` is now rejected as an unknown argument

- [x] update: [sys/softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
  - update: header comment block to remove the "evaluate concurrency and pass --concurrency" paragraph
  - remove: "Construction todos include concurrency-evaluation instruction" test
  - remove: "specs-side todos do NOT include concurrency-evaluation instruction" test

### Implementation

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: `cmd_self_review` usage comment and stage validation to drop `C` from the allowed `--stage` values
  - remove: `--concurrency` flag parsing, the `opt_concurrency` local, the `--concurrency requires --type construction` validation, and the `[concurrency]` entry in the `review_vars` map
  - remove: the `concurrency` field from the prompt-variable map passed by `cmd_action_uimpl` to `instr_uimpl_todos`, and the `chain_self_review_construction` local that gates it

- [x] update: [prompts/include_chain_self_review.md](../../../../../bin/prompts/include_chain_self_review.md)
  - remove: the "Silently evaluate whether the completed changes touch concurrency-sensitive code paths..." bullet that depends on `(?chain_self_review_construction)`

- [x] update: [prompts/instr_self_review_construction_a.md](../../../../../bin/prompts/instr_self_review_construction_a.md)
  - update: trailing "invoke the next stage" block to a single unconditional `Run bash "${softeng_sh}" self-review --type construction --stage B` line (drop the `(?concurrency)` / `(?!concurrency)` pair)

- [x] update: [prompts/instr_self_review_construction_b.md](../../../../../bin/prompts/instr_self_review_construction_b.md)
  - update: trailing instructions to a single unconditional "Report results to the user" line (drop the `(?concurrency)` Stage C hand-off and the `(?!concurrency)` qualifier on the report line)

- [x] remove: `[prompts/instr_self_review_construction_c.md](../../../../../bin/prompts/instr_self_review_construction_c.md)`

- [x] update: [_lib/utils.sh](../../../../../bin/_lib/utils.sh)
  - update: tag-along fix unrelated to concurrency removal — escape `/` inside the `[^/]` character classes in `md_defang_relative_link` so BSD awk (macOS default) does not abort with `nonterminated character class` on every `upr` invocation
