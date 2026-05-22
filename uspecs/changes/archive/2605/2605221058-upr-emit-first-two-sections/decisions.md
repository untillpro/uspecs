# Decisions

## Uncertainty: whether `upr` should preserve named-section handling or use one uniform body rule

Decision: Emit all body content from the first top-level `##` section, then apply size limits

- Pros: simplest reviewer-facing rule; handles arbitrary section names consistently; avoids omitting useful short sections
- Cons: PR bodies may include more sections than before until the size limit is reached
- Confidence: high

Alternatives:

1. Emit all body content from the first top-level `##` section, then apply size limits
   - Pros: simple rule; bounded by existing 40-line and 4000-character guards; no arbitrary section count
   - Cons: larger PR bodies when change files have several short sections
   - Confidence: high
2. Uniform first two `##` sections after frontmatter
   - Pros: directly matches issue #105; keeps PR bodies shorter
   - Cons: arbitrary cutoff; can omit useful content even when the body is still small
   - Confidence: medium
3. Preserve `## Context` as a special shape, but apply generic logic to non-context changes
   - Pros: minimizes behavior change for fetchable issue-shaped change files
   - Cons: keeps two body assembly modes; less predictable for users
   - Confidence: low

## Uncertainty: when `upr` should append the omission note

Decision: Append `Content omitted. See change.md for full details.` only when the PR body is truncated by line or character limits

- Pros: the note now means actual content was removed by a size guard; avoids implying section-based omission
- Cons: reviewers are not reminded to open `change.md` when the full body fits
- Confidence: high

Alternatives:

1. Append the omission note only when size truncation occurs
   - Pros: precise signal; aligns with the removal of section-count omission
   - Cons: no extra cue when the body fits
   - Confidence: high
2. Always append a plain `See change.md for details` note
   - Pros: consistent pointer to source material
   - Cons: noisy when the full body is already present
   - Confidence: medium
3. Keep section-count omission and append the note at the third `##`
   - Pros: shorter PR bodies
   - Cons: preserves the arbitrary cutoff this change removes
   - Confidence: low

## Uncertainty: which behavior should get system-test coverage for this fix

Decision: Cover arbitrary section names, all-section inclusion, and size truncation

- Pros: verifies the core fix, the removal of the section limit, and the retained bounded-body behavior
- Cons: broader than the issue's minimal reproduction
- Confidence: high

Alternatives:

1. Cover arbitrary section names, all-section inclusion, and size truncation
   - Pros: covers the complete behavior contract
   - Cons: a few more assertions to maintain
   - Confidence: high
2. Cover only `## Why` + `## How` PR body assembly
   - Pros: directly reproduces issue #105
   - Cons: would not prove the section limit was removed
   - Confidence: medium
