# Decisions: Frontmatter scope field inference

## Uncertainty: frontmatter `scope` value shape

Decision: Use unqualified context names by default, and use domain-qualified `domain/context` entries only when duplicate context names would otherwise make `scope` ambiguous.

- Pros: Keeps common single-domain scope values concise while preserving a deterministic representation for multi-domain context-name conflicts.
- Cons: Consumers must support both unqualified and domain-qualified scope entry forms.
- Confidence: user-provided

Alternatives:

1. Always use domain-qualified context entries
   - Pros: Avoids ambiguity in every case and gives one uniform interpretation rule.
   - Cons: More verbose than necessary for common single-domain changes.
   - Confidence: high
2. Always use unqualified context names
   - Pros: Concise and simple for authors and reviewers.
   - Cons: Ambiguous when multiple affected domains define the same context name.
   - Confidence: medium
3. Use a YAML mapping from domain to contexts
   - Pros: Explicit and structured for multi-domain changes.
   - Cons: Heavier frontmatter shape than the existing flow-list style.
   - Confidence: medium

## Inconsistency: duplicate context names are now resolved, but the original request said to fail

Decision: Use `domain/context` only for conflicting context names.

- Pros: Keeps change creation automatic while preserving disambiguation for context-name conflicts.
- Cons: Overrides the original fail-on-conflict requirement.
- Confidence: user-provided

Alternatives:

1. Fail when multiple affected domains contain the same inferred context name
   - Pros: Matches the original requirement exactly and forces the Engineer to clarify ambiguous scope.
   - Cons: Makes conflict cases non-automatic even though `domain/context` can represent them.
   - Confidence: high
2. Fail only when the AI Agent cannot confidently choose the affected domain-qualified contexts
   - Pros: Supports automatic disambiguation where clear and still fails on genuinely ambiguous cases.
   - Cons: Introduces a confidence-based rule that may be less deterministic.
   - Confidence: medium

## Vagueness: when `scope` should be omitted

Decision: Omit `scope` when no affected context can be inferred confidently.

- Pros: Matches best-effort domain inference without inventing unsupported precision and avoids misleading scope values.
- Cons: Some valid changes will have `domains` but no `scope`.
- Confidence: user-provided

Alternatives:

1. Always emit `scope`, using all contexts from affected domains when unsure
   - Pros: Guarantees frontmatter shape is present for downstream consumers.
   - Cons: Overstates blast radius and can make broad scope look intentional.
   - Confidence: low
2. Fail when affected domains are inferred but no context can be inferred
   - Pros: Forces precise change requests.
   - Cons: Makes uchange more brittle for broad or early-stage requests where domain-level scope is enough.
   - Confidence: medium
