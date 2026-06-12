# Decisions: Fault signal in What and uchange planning options removal

## Ambiguity: when exactly does the uimpl fault localization gate trigger

Decision: Gate triggers only for `type: fix` Change Files where the marker appears as a step inside the `## What` section's fenced flowchart block

- Pros: precise; immune to false positives from change requests that merely quote the marker in prose or examples; consistent with the marker being defined only for fix-style What
- Cons: needs the frontmatter type check in addition to the section/fence-aware scan
- Confidence: high

Alternatives:

1. Gate triggers when the marker text appears anywhere in the Change File
   - Pros: simplest possible rule to specify and implement
   - Cons: false positives on `feat`/`docs` changes that quote the marker
   - Confidence: low
2. Gate triggers when the marker appears anywhere within the `## What` section, regardless of frontmatter type
   - Pros: no dependence on the `type:` field, so fix-style What in a mistyped change is still gated
   - Cons: still false-positives when `## What` quotes the marker in prose or example blocks
   - Confidence: medium

## Inconsistency: "uchange always produces only the Why and What sections" contradicts the fetchable Resolves block

Decision: Scope the claim to planning content -- `uchange` no longer authors `## How` or implementation-plan sections; the rest of the change request shape (heading, optional Resolves, Why, What) is unchanged

- Pros: states the actual intent; preserves issue traceability for fetchable flows; no hidden behavior change
- Cons: slightly longer wording
- Confidence: high

Alternatives:

1. Keep the literal claim and also remove the `## Resolves` block from fetchable flows
   - Pros: literally simpler output contract
   - Cons: drops issue traceability for no stated reason; expands scope; contradicts the `--fetchable`/`--issue-url` options that remain
   - Confidence: low

## Vagueness: how much localization effort is expected at uchange time

Decision: Quick static investigation with a numeric budget and a stop rule -- the agent may read and search the codebase but must not run code or tests and must not attempt to reproduce the symptom; capped at roughly 5 searches and 10 file reads, stopping earlier as soon as pinning the fault would require verification rather than reading. When either limit is hit without an evident fault, the marker is placed and localization belongs to the `uimpl` gate

- Pros: static-only is a hard, binary boundary; the numeric budget catches "one more file" creep while the stop rule catches "this needs an experiment"; faults one hop beyond the named artifacts are still localizable cheaply
- Cons: the budget numbers are arbitrary; a cap slightly too low marks faults that were one read away
- Confidence: user-provided

Alternatives:

1. Read only artifacts directly named or unambiguously implied by the input; no codebase searching
   - Pros: strictest operational bound; zero wandering
   - Cons: a fault one hop from the named artifact gets pushed through the full `uimpl` gate ceremony unnecessarily
   - Confidence: medium
2. Input-only: the marker is omitted only when the input itself names the fault and the causal link
   - Pros: fully deterministic; zero investigation at `uchange` time
   - Cons: misses cases where a trivial lookup would localize the fault; previously rejected input-based framing
   - Confidence: medium
3. Unbounded: the agent may investigate as long as needed during `uchange` to localize the fault
   - Pros: maximizes localized flowcharts up front
   - Cons: makes `uchange` slow; duplicates the `uimpl` gate's purpose; localization efforts outside `fault.md` tracking
   - Confidence: low
