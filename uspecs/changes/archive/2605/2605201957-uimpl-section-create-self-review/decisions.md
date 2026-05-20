# Decisions

## Uncertainty: what is the review subject when the chain fires after section creation

Decision: Adapt the existing Stage A specs prompt to review specs and/or to-do items

- Pros: agent's best-effort assessment - keeps a single Stage A prompt for all three triggers (post-todos, section-creation in `uimpl`, plan-creation in `uchange --plan`); minimal taxonomy change in `self-review.feature`; reuses the existing `--type specs --stage A` wiring without introducing a new type or stage
- Cons: agent's best-effort assessment - the prompt subject is broader, so the agent must hold both "spec edits" and "plan bullet edits" in mind; the wording change must remain accurate when only one of the two kinds of edits is present in a given cycle
- Confidence: user-provided

Alternatives:

1. Introduce a new prompt `instr_self_review_plan_a.md` and a new `--type plan`
   - Pros: clean separation of concerns; each prompt has a single subject
   - Cons: new type/stage taxonomy to wire through `cmd_self_review`, validation, docs, and `self-review.feature`; larger surface area
   - Confidence: medium
2. Pass a context variable (e.g. `review_target=plan_bullets`) into the existing Stage A specs prompt with conditional sections
   - Pros: one command, one prompt file; branching driven by data
   - Cons: prompt template becomes conditional-heavy; harder to read and test
   - Confidence: medium
3. Drop the section-creation chain and trigger one specs review only when the final section (Construction) is appended
   - Pros: review the plan as a coherent whole once it stabilizes; minimal noise
   - Cons: contradicts the stated intent ("creating any section"); delays feedback on early misalignments
   - Confidence: low

## Uncertainty: should the chain fire on the "plan is completed" notice cycle (no section appended)

Decision: Gate `chain_self_review` script-side in `cmd_action_uimpl`; set it only when a section is actually being appended (or all unchecked to-dos were completed, the existing post-todos subcase). The prompt host site uses a single `(?chain_self_review)` gate around the shared include

- Pros: gating decided once in the script; prompt templates stay simple; matches how the post-todos chain is already gated script-side; same pattern reused for `cmd_action_uchange` (which gates on `impl_maybe`)
- Cons: gating logic is split across two callers (`cmd_action_uimpl` and `cmd_action_uchange`) rather than living in one place
- Confidence: user-provided

Alternatives:

1. Gate the chain block in `instr_uimpl.md` on `(?chain_self_review)(?constr_maybe)` so the template discriminates the section-append vs completion-notice subcases
   - Pros: reuses the existing `constr_maybe` master flag that already discriminates the subcases inside `instr_uimpl.md`; no script-side branching
   - Cons: the chain block carries two gates; cannot be deduplicated into a shared include without each host site adding its own outer gate; inconsistent with how the post-todos chain is gated
   - Confidence: medium
2. Always fire the chain on the completion subcase too (one final consistency pass)
   - Pros: gives a closing consistency pass over the now-stable plan
   - Cons: contradicts the Out-of-scope item; produces a no-op review when no spec or plan edits happened in this cycle
   - Confidence: low

## Uncertainty: should the chain block be duplicated across instr_uimpl, instr_uimpl_todos, and instr_uchange or factored into a shared include

Decision: Factor the chain block into `bin/prompts/include_chain_self_review.md` and reference it via `@include_chain_self_review` from all three host templates

- Pros: single source of truth for the chain instructions (announce + invoke `self-review`); the same retry-budget rendering applies uniformly to all three callers; future tweaks (e.g. wording, additional context vars) require editing one file
- Cons: introduces one more include file; readers of any single host template must follow the include to see the chain text
- Confidence: user-provided

Alternatives:

1. Duplicate the chain block inline in each host template
   - Pros: each template is self-contained and readable end-to-end
   - Cons: three copies to keep in sync; drift risk grows with each new caller (e.g. if a future `uarchive` or `usync` ever chains a review)
   - Confidence: medium

## Uncertainty: should uchange chain self-review unconditionally or only when --plan is passed

Decision: Chain only when `--plan` is passed (i.e. `impl_maybe` is set)

- Pros: matches the "no work, no review" principle - default `uchange`, `--how`, and `--fetchable` invocations produce no plan bullets and no spec references, so a review would have an empty subject; aligns with the `uimpl` gating which fires only on section-append cycles
- Cons: requires the engineer to remember that `--plan` is the trigger; an engineer who later edits the change request to add a plan section manually will not get an auto-review
- Confidence: user-provided

Alternatives:

1. Chain on every `uchange` invocation
   - Pros: uniform behavior; no flag-dependent gating
   - Cons: most invocations have nothing to review; wastes a review pass on Why/What-only change requests
   - Confidence: low
2. Chain on `--plan` or `--how`
   - Pros: covers the case where `--how` adds a design narrative referencing specs
   - Cons: `## How` is prose-only and not a list of plan bullets that reference spec files; the Stage A specs prompt is not the right subject for it
   - Confidence: low

## Uncertainty: should specs self-review support a retry budget

Decision: Add `-b N` to `self-review --type specs` only; reject `-b` for `--type construction`

- Pros: a single review pass that fixes issues inline may itself introduce follow-on issues; a bounded retry loop catches cascading issues without unbounded looping; symmetric to the `--concurrency requires --type construction` validation rule; specs is single-stage (Stage A only) so the budget mechanism is self-contained with no cross-stage interaction questions
- Cons: new flag adds parsing and validation surface; agent must follow the rendered next-invocation command verbatim
- Confidence: user-provided

Alternatives:

1. No retry budget; keep the single-pass behavior
   - Pros: simplest; matches current behavior
   - Cons: misses follow-on issues introduced by the fixes in the current pass
   - Confidence: low
2. Extend `-b` to construction too
   - Pros: uniform retry semantics across types
   - Cons: construction has three stages (A/B/C) with cross-stage flow questions (budget reset on stage advance, dirty pass with exhausted budget, etc.); a separate change is warranted
   - Confidence: medium

## Uncertainty: how should the retry budget be decremented and the next-invocation command rendered

Decision: Script-side decrement; render the literal next-invocation command into the prompt under a `(?budget)` block

- Pros: agent performs no arithmetic; the rendered command is verbatim and unambiguous; the prompt template stays declarative; mirrors how other context vars (e.g. `concurrency`) drive prompt branches; clean fixed-point termination (a pass that finds zero issues stops without consuming the rest of the budget)
- Cons: the prompt now has a conditional block keyed on `budget`; readers must check the `(?budget)` / `(?!budget)` branches
- Confidence: user-provided

Alternatives:

1. Have the agent compute `(N-1)` and re-invoke
   - Pros: prompt template is unconditional
   - Cons: agents are unreliable at arithmetic in instructions; risk of off-by-one or wrong-flag bugs
   - Confidence: low
2. Use unconditional re-invocation while budget remains (no "new issues detected" check)
   - Pros: simplest loop condition; no agent judgment required
   - Cons: wastes passes when the first pass already found nothing; budget effectively becomes "always do N+1 passes" instead of "retry only if needed"
   - Confidence: low

## Uncertainty: what default -b should the auto-chains in uimpl and uchange attach

Decision: Default `-b 4` for both auto-chains (initial pass + up to 4 retries)

- Pros: small constant catches one or two layers of cascading issues without exploding pass counts; no new engineer-facing flag needed; `--no-self-review` still suppresses entirely
- Cons: a fixed default may be too low for large section drafts or too high for trivial ones; revisitable in a follow-up
- Confidence: user-provided

Alternatives:

1. Default `-b 0` (no retries unless the engineer explicitly opts in)
   - Pros: zero behavior drift from current single-pass model
   - Cons: defeats the purpose of adding the budget mechanism in the same change
   - Confidence: medium
2. Expose `--review-budget N` on `uimpl` and `uchange` so the engineer picks per invocation
   - Pros: full control; no opinionated default
   - Cons: extra flag surface on two actions; most invocations will just want the default
   - Confidence: medium

## Uncertainty: how to handle the existing "Do not re-run this stage" rule in `instr_self_review_specs_a.md` when adding the `(?budget)` retry block

Decision: Remove "Do not re-run this stage" entirely; the budget mechanism is the sole termination control

- Pros: cleanest result - no contradictory rules in the prompt; the only re-run path is the budget-controlled one, which is self-terminating (zero-issue fixed point or `-b 0`); single conditional `(?budget)` retry block + unconditional report tail is easy to read
- Cons: drops a guardrail that prevented unbounded re-runs before the budget existed; relies entirely on the budget for termination
- Confidence: user-provided

Alternatives:

1. Keep "Do not re-run this stage" under `(?!budget)`; render the retry block only under `(?budget)`
   - Pros: preserves current behavior when `-b` is absent; both branches are explicit
   - Cons: the rule now lives in a conditional, slightly awkward to read; auto-chains always pass `-b 4`, so the `(?!budget)` branch fires only on manual `self-review --type specs --stage A` without `-b`
   - Confidence: medium
2. Rephrase the rule to "Do not re-run this stage unless instructed by the retry block below" - kept unconditional
   - Pros: single unconditional rule; explicit cross-reference to the budget block
   - Cons: forward reference inside the rules section; reader must scan ahead to see what "the retry block below" means
   - Confidence: low

## Uncertainty: how should `-b 0` and the boundary `next_budget` value be handled to make the retry chain terminate cleanly

Decision: Validate `N >= 0`; set `budget` (the prompt gate) and `next_budget=N-1` only when `N > 0`; `-b 0` is accepted but suppresses the retry block, giving a clean terminal step

- Pros: `-b 0` is a meaningful explicit terminal state - the chain `-b 4 -> -b 3 -> -b 2 -> -b 1 -> -b 0` ends naturally without rendering `-b -1`; the retry block is uniformly gated by `budget` set/unset, no special-case for negative `next_budget`; engineer can manually invoke `-b 0` to get exactly one pass with no retries
- Cons: two distinct paths lead to suppressing the retry block ("`-b` absent" and "`-b 0`"), both rendering the same prompt; reader must understand both produce identical output
- Confidence: user-provided

Alternatives:

1. Validate `N >= 1`; reject `-b 0` as a parse error
   - Pros: simplest validation rule
   - Cons: the auto-chain `-b 4 -> -b 3 -> ... -> -b 0` would error on the final invocation; would force the retry block to gate on `next_budget > 0`, complicating the prompt
   - Confidence: low
2. Validate `N >= 1`; render the retry block only when `next_budget >= 1`
   - Pros: retry block only present when a further retry is still possible
   - Cons: `-b N` effectively means "up to N-1 retries" instead of N; off-by-one trap
   - Confidence: low
