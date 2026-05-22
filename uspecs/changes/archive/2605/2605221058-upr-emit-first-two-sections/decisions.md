# Decisions

## Uncertainty: whether `upr` should preserve special `## Context` handling or use one uniform "first two sections" rule

Decision: Uniform first two `##` sections after frontmatter

- Pros: directly matches issue #105; simplest rule to explain and test; handles `## Why` + `## How` and future section names consistently
- Cons: changes current special behavior for `## Context` if downstream sections were intentionally excluded differently
- Confidence: high

Alternatives:

1. Uniform first two `##` sections after frontmatter
   - Pros: directly matches issue #105; simplest rule to explain and test; handles `## Why` + `## How` and future section names consistently
   - Cons: changes current special behavior for `## Context` if downstream sections were intentionally excluded differently
   - Confidence: high
2. Preserve `## Context` as a special shape, but apply first-two logic to non-context changes
   - Pros: minimizes behavior change for fetchable issue-shaped change files; lower regression risk if `## Context` has special semantics
   - Cons: does not fully satisfy "regardless of their headings"; keeps two body assembly modes
   - Confidence: medium
3. Emit frontmatter plus all sections until the third `##`, then add "See change.md for details."
   - Pros: preserves the existing detail note pattern for longer files; makes truncation boundary explicit
   - Cons: mostly equivalent to option 1 but less direct; may duplicate truncation semantics
   - Confidence: medium

## Uncertainty: whether `upr` should append "See change.md for details." when `change.md` has more than two body sections

Decision: Keep the details note when a third top-level `##` section exists, using a plain omission note instead of a Markdown link

- Pros: preserves the existing reviewer cue that more content was intentionally omitted; compatible with the current plain-text commit trailer style
- Cons: slightly expands the requested behavior beyond "emit the first two sections"
- Confidence: high

Alternatives:

1. Keep the details note when a third top-level `##` section exists
   - Pros: preserves the existing reviewer cue that more content was intentionally omitted; compatible with the current PR body style
   - Cons: slightly expands the requested behavior beyond "emit the first two sections"
   - Confidence: high
2. Omit the details note and emit only the first two sections
   - Pros: literal interpretation of issue #105; simpler output
   - Cons: reviewers may not realize additional sections exist unless they open `change.md`
   - Confidence: medium
3. Emit the details note only when body-size truncation occurs
   - Pros: ties the note strictly to the existing size guards
   - Cons: loses the current signal for section-based omission; conflates omitted sections with size truncation
   - Confidence: low

## Uncertainty: which behavior should get system-test coverage for this fix

Decision: Cover both `## Why` + `## How` and a third omitted section

- Pros: verifies the core fix and the retained details-note behavior; covers the boundary where only two sections are emitted
- Cons: slightly broader than the issue's minimal reproduction
- Confidence: high

Alternatives:

1. Cover `## Why` + `## How` PR body assembly
   - Pros: directly reproduces issue #105; proves arbitrary second heading names are retained
   - Cons: only covers the reported case, not the general first-two-section rule
   - Confidence: high
2. Cover both `## Why` + `## How` and a third omitted section
   - Pros: verifies the core fix and the retained details-note behavior; covers the boundary where only two sections are emitted
   - Cons: slightly broader than the issue's minimal reproduction
   - Confidence: high
3. Cover several arbitrary heading combinations
   - Pros: strongly validates the uniform heading-agnostic rule
   - Cons: more test cases for a small parser change; higher maintenance cost
   - Confidence: medium
