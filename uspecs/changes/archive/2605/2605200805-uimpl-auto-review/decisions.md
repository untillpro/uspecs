# Decisions

## Uncertainty: How does the AI Agent traverse self-review stages?

Decision: Sequential one-call-per-stage with explicit chain hand-off, and `self-review` is a top-level softeng command (not under `action`)

- Pros: matches softeng's existing one-prompt-per-call dispatch pattern; fresh attention budget per stage; smaller, more testable prompt templates; agent can skip a stage cleanly; consistent with the "softeng is a pure dispatcher" decision; top-level placement signals this command is agent-driven plumbing rather than an Engineer-facing action
- Cons: more round-trips than a single-call design; the Agent must remember to advance from stage to stage; top-level command sits outside the `action` registry so it bypasses the standard action dispatch path
- Confidence: user-provided

Alternatives:

1. Single call returns all applicable stages as one prompt
   - Pros: one round-trip; simpler Agent flow
   - Cons: long prompt; later stages compete with earlier stages for attention; collides with the "fresh prompt = fresh attention" rationale for auto-review
   - Confidence: medium
2. softeng tracks current stage server-side (state file in Change Folder)
   - Pros: Agent never has to track stages; clean termination signal
   - Cons: introduces state on softeng's side, contradicting the "pure prompt dispatcher" decision
   - Confidence: low
3. Stages bundled into two calls (consistency, then code quality), with `--concurrency` triggering a third
   - Pros: fewer round-trips than sequential per-stage
   - Cons: still Agent-driven progression; hybrid design is harder to document; no clear win over per-stage chaining
   - Confidence: low

## Uncertainty: Should specs and construction have parallel stage structures, and what does DRY/SOLID mean for specs?

Decision: Keep the bundled specs Stage A (Scope 1 = consistency with change request, Scope 2 = DRY across specs); drop SOLID from specs. Construction stage layout (A consistency / B DRY+SOLID / C optional concurrency) is unchanged.

- Pros: scopes the specs self-review to what is meaningful for spec artifacts (alignment with change request, no duplicate spec content); avoids forcing code-only concepts onto specs; keeps the existing draft layout with only a content trim
- Cons: stage structures remain asymmetric across types (specs has one stage, construction has two-to-three); construction reference "same as specs A.1" relies on readers parsing the implicit scope numbering
- Confidence: user-provided

Alternatives:

1. Drop DRY/SOLID from specs entirely; specs Stage A covers consistency only
   - Pros: maximally simple specs path; clean separation of "specs = alignment, construction = code quality"
   - Cons: duplicate spec content goes uncaught by self-review
   - Confidence: medium
2. Parallel layout: split specs into Stage A (consistency) and Stage B (DRY across specs); drop SOLID from specs
   - Pros: symmetric stage structure with construction; easier prompt template parity
   - Cons: extra round-trip per specs self-review; one of the motivations for bundling was that specs are smaller surfaces
   - Confidence: medium
3. Keep DRY and SOLID for specs (status quo of original draft)
   - Pros: maximum coverage
   - Cons: SOLID is a code-design principle and does not map cleanly onto spec artifacts
   - Confidence: low

## Uncertainty: What does the Agent do when it finds issues during a self-review stage?

Decision: Fix inline, then advance to the next stage. No re-run of the same stage; each stage runs exactly once.

- Pros: matches the spirit of "stages replace the loop" decided earlier; finite, predictable trajectory; trivial to test (each stage prompt produces one Agent pass); no risk of infinite-loop or wasted tokens; simplest mental model
- Cons: a fix made during Stage A could introduce a regression that Stage A would have caught; relies on fixes being small and local
- Confidence: high

Alternatives:

1. Fix inline, then re-run the same stage until clean, then advance
   - Pros: each stage is "complete" before progression; catches regressions introduced by fixes
   - Cons: reintroduces the looping problem `-n` was meant to bound; no termination guarantee
   - Confidence: low
2. Fix inline + bounded retry per stage; unresolved findings appended as new todos in impl.md
   - Pros: bounded; allows some self-correction; unresolved findings stay visible and get picked up by next uimpl
   - Cons: adds budget logic per stage; modifying impl.md changes uimpl's behavior on the next call
   - Confidence: medium
3. Identify and report only; no fixes during self-review
   - Pros: cleanest separation between review and implementation; no risk of self-review introducing bugs
   - Cons: contradicts the "raises baseline quality without Engineer intervention" goal
   - Confidence: medium
4. Fix inline + append unresolved findings as new unchecked todos in impl.md; advance
   - Pros: nothing falls on the floor; fits existing uimpl cycle
   - Cons: blurs the line between review and implementation; new todos may not match engineer-authored structure
   - Confidence: medium

## Uncertainty: When and how does the Agent decide to pass `--concurrency`?

Decision: The uimpl emit response explicitly instructs the Agent to evaluate concurrency relevance whenever Construction todos were completed in this uimpl invocation. The Agent passes the result back to softeng as `--concurrency` (set or omitted) on the self-review chain command. `--concurrency` is then a plain input flag to self-review that propagates unchanged through Stage A -> B -> C and gates Stage C.

- Pros: explicit instruction beats implicit self-assessment; single decision point at the uimpl -> self-review boundary; self-review remains a pure dispatcher of an externally-decided boolean; flag value is fixed before Stage A runs, so the chain is internally consistent; concurrency reasoning lives where the implementation knowledge is freshest (right after Construction todos were completed)
- Cons: requires a dedicated scenario in uimpl.feature to document the evaluation instruction; cross-feature responsibility (uimpl decides, self-review consumes); misses concurrency hints that only become visible during a later stage
- Confidence: high

Note: Earlier wording placed the self-assessment "at the first construction stage invocation (Stage A)" with the Agent including `--concurrency` on its own Stage A call. That phrasing left ambiguous whether Stage A would need to re-invoke itself; the revised decision resolves the ambiguity by moving the evaluation explicitly to uimpl emit time.

Alternatives:

1. Engineer sets `--concurrency` via a `uimpl --concurrency` flag; uimpl propagates it
   - Pros: deterministic, Engineer-controlled, explicit
   - Cons: easy to forget; Engineer may not know in advance; sits against the "no Engineer intervention" goal
   - Confidence: medium
2. Drop the flag; construction Stage C runs unconditionally
   - Pros: simpler interface; predictable finite stage count
   - Cons: extra tokens on changes with no concurrency relevance; loses the "optional" intent of Stage C
   - Confidence: medium
3. Drop the runtime flag; gate Stage C behind an explicit `uimpl --concurrency` so the flag never reaches self-review
   - Pros: minimal self-review CLI; explicit gate
   - Cons: easy to forget; redundant with alternative 1's downsides
   - Confidence: low
