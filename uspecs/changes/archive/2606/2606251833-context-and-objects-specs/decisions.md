# Decisions: Introduce context.md as the bounded context and tactical design artifact

## Inconsistency: object specification scope is unclear

Decision: Tactical Design Elements live inside `context.md`, with structural elements documented in `## Model specification` and behavior/lifecycle elements documented in `## Lifecycle and behavior`; do not introduce separate object specification artifacts.

- Pros: Keeps `context.md` as the authoritative Bounded Context artifact and matches the existing DDD rules and example context structure.
- Cons: Large or object-heavy contexts must keep their tactical model readable within one artifact.
- Confidence: user-provided

Alternatives:

1. Introduce separate object specification artifacts in addition to `context.md`
   - Pros: Gives tactical objects their own detailed homes.
   - Cons: Weakens `context.md` as the authoritative context model and requires new path/layout rules.
   - Confidence: medium
2. Support both embedded object specs and optional separate object specs
   - Pros: Flexible for small and large contexts.
   - Cons: Creates two valid documentation styles immediately, making skills and examples harder to enforce consistently.
   - Confidence: low

## Inconsistency: Modules are listed as a missing DDD tactical concept but are not defined in the finalized DDD rules

Decision: Defer Modules and remove them from the stated scope of this change.

- Pros: Keeps this change focused on the Tactical Design Elements currently defined in the reusable DDD rules: Entities, Value Objects, Aggregates, Services, Events, Repositories, and Factories.
- Cons: Leaves module organization to a future clarification or change.
- Confidence: high

Alternatives:

1. Add Modules as an optional Tactical Design Element in `context.md`
   - Pros: Matches the earlier stated motivation and gives model organization a clear home.
   - Cons: Requires defining whether Modules are part of `## Model specification`, `## Lifecycle and behavior`, or a separate section.
   - Confidence: high
2. Treat Modules as implementation/package structure, not a specification concept
   - Pros: Avoids documenting source-layout concerns in domain specs.
   - Cons: Still requires explaining why Modules were listed as a DDD tactical-model gap.
   - Confidence: medium

## Ambiguity: path-template policy could apply to every skill or only the domain-related skills changed here

Decision: The domain-related skills changed by this request may use artifact path templates for Domain Specification and Bounded Context Specification files.

- Pros: Restores concise artifact guidance and aligns the skills with the existing path-template style.
- Cons: Leaves other skills' path-handling rules outside the scope of this decision.
- Confidence: high

Alternatives:

1. Apply the path-template policy to every skill
   - Pros: Creates one framework-wide path style.
   - Cons: Overreaches this change request and may affect unrelated skills without review.
   - Confidence: medium
2. Require domain-related skills to get all concrete target paths only from `softeng.sh` action output
   - Pros: Avoids reusable path templates in skill text.
   - Cons: Removes useful artifact path templates from reusable skill guidance.
   - Confidence: low

## Ambiguity: `uspecs-concepts` should reference `uspecs-domains`, but it is unclear how much DDD content should remain there

Decision: Keep only a lightweight DDD overview in `uspecs-concepts`; move detailed domain/context/tactical authoring rules and examples to `uspecs-domains`.

- Pros: Preserves `uspecs-concepts` as a useful framework index while making `uspecs-domains` the rule source of truth.
- Cons: Requires carefully distinguishing overview content from authoring-rule content.
- Confidence: high

Alternatives:

1. Replace the DDD section in `uspecs-concepts` with a pointer to `uspecs-domains`
   - Pros: Strongest single-source-of-truth interpretation.
   - Cons: Makes `uspecs-concepts` less useful for explaining basic framework concepts.
   - Confidence: medium
2. Keep DDD concept definitions in `uspecs-concepts` and only link to `uspecs-domains` for examples
   - Pros: Minimal disruption to existing concepts skill.
   - Cons: Contradicts the requirement that `uspecs-concepts` should reference `uspecs-domains` rather than explain the rules itself.
   - Confidence: low

## Vagueness: `uspecs-domains` should carry new rules and examples, but the source role of draft rule/example files is unclear

Decision: The temporary draft rule/example files were implementation inputs; after materialization, the reusable `uspecs-domains` skill materials carry the finalized DDD rules and examples.

- Pros: Keeps reusable skill materials as the active source for future agents and avoids retaining duplicate change-folder drafts.
- Cons: Loses a separate source draft that could be diffed against the skill materials.
- Confidence: user-provided

Alternatives:

1. Keep draft rule and example files in the Change Folder as equally normative
   - Pros: Preserves the original drafted materials.
   - Cons: Examples may accidentally define rules not stated in reusable skill guidance, and duplicated sources can drift.
   - Confidence: medium
2. Treat `change.md` requirements as the only normative source
   - Pros: Keeps implementation tied to the formal request.
   - Cons: Loses much of the detailed DDD design captured in reusable skill materials.
   - Confidence: low

## Vagueness: `uspecs-domains` should apply to `domain.md` and `context.md`, but authoring behavior for each artifact is not explicit

Decision: Define `uspecs-domains` as the authoring/review skill for Domain Design Specifications, including Domain Specifications and Bounded Context Specifications, and as the assistance skill for DDD modeling questions about domain boundaries, context boundaries, ubiquitous language, tactical design, lifecycle, and behavior, with separate sections for each specification type.

- Pros: Gives one skill clear ownership of shared DDD vocabulary while keeping domain-level and context-level rules separated, and makes the DDD guidance discoverable even when the user is not editing a spec file yet.
- Cons: Makes the skill broader and longer.
- Confidence: high

Alternatives:

1. Keep `uspecs-domains` primarily domain-focused and add only a brief `context.md` subsection
   - Pros: Smaller change to the current skill.
   - Cons: Context rules may be too thin for the new tactical design artifact.
   - Confidence: medium
2. Introduce a new `uspecs-contexts` skill for `context.md`
   - Pros: Clean separation of domain and context authoring concerns.
   - Cons: Larger workflow change and contradicts the current requirement that `uspecs-domains` should apply to both files.
   - Confidence: low

## Ambiguity: `uspecs-sec-domains` should mention context files, but it is unclear whether `## Domain specifications` should include context todos or only cross-reference them

Decision: Keep context todos inside `## Domain specifications` as Bounded Context Specification items, and give `uspecs-sec-domains` concrete impact-assessment guidance for deciding whether Domain Design Specification todos are needed. Use `uspecs-domains` only when substantive DDD modeling or specification content is required.

- Pros: Domain Design Specification todos stay in one planning section and no new section type is introduced; routine impact checks avoid loading the heavier DDD authoring skill.
- Cons: The section name becomes broader than `domain.md` alone, and the planning skill must carry enough concrete guidance to decide when a todo is needed.
- Confidence: high

Alternatives:

1. Mention context files only as notes under `domain.md` todo items
   - Pros: Minimal change to existing planning format.
   - Cons: Context work may be less visible and less independently actionable.
   - Confidence: medium
2. Add a new planning section for Bounded Context specifications
   - Pros: Explicit and easy to scan.
   - Cons: Introduces a new section type and broadens workflow changes.
   - Confidence: low

## Inconsistency: `change.md` says Domain Events, but the finalized DDD rules name the Tactical Design Element Event

Decision: Standardize on `Event` as the artifact term, with "domain event" used only descriptively.

- Pros: Matches the current reusable Tactical Design Elements list and keeps section names concise.
- Cons: May be slightly less explicit for readers familiar with DDD's "Domain Event" term.
- Confidence: high

Alternatives:

1. Standardize on `Domain Event` everywhere
   - Pros: Aligns with common DDD terminology and makes clear these are domain-level occurrences, not technical events.
   - Cons: Requires updating reusable DDD rules and examples from `Event`/`Events` wording.
   - Confidence: medium
2. Define `Event` as shorthand for `Domain Event`
   - Pros: Preserves existing concise wording while removing ambiguity.
   - Cons: Leaves two terms in circulation.
   - Confidence: medium

## Ambiguity: source background links included private or draft-only sources, but reusable skill reference scope is unclear

Decision: Carry only stable, public DDD references into reusable rationale/reference materials; keep private or draft-only links out of reusable materials.

- Pros: Avoids baking inaccessible or private context into reusable skills and keeps reusable docs portable; keeps background references out of the main authoring skill unless rationale is needed.
- Cons: Loses a breadcrumb to the original design discussion unless retained only in the Change Folder.
- Confidence: high

Alternatives:

1. Keep all source background links in the extracted reference file
   - Pros: Preserves full provenance from the source artifact.
   - Cons: Private links may be inaccessible or inappropriate for reusable skill docs.
   - Confidence: medium
2. Remove all external references from skill materials and rely only on adapted rules
   - Pros: Keeps skill docs self-contained and concise.
   - Cons: Removes useful source attribution for DDD concepts.
   - Confidence: medium

## Ambiguity: domain-related skills may use path templates

Decision: Use Domain Design Specifications as the family term, keep Domain Specification and Bounded Context Specification as concrete specification types, and have the domain-related skills changed by this request include a shared Domain Design Specification artifact snippet for path templates.

- Pros: Restores the previous path-template style, avoids duplicating artifact definitions across skills, and aligns reusable artifact names with the skills' terminology.
- Cons: Path-template policy remains scoped to the domain-related skills changed by this request, and the shared snippet becomes another file to maintain.
- Confidence: user-provided

Alternatives:

1. Keep path templates out of the domain-related skills
   - Pros: Avoids reusable path templates in skill text.
   - Cons: Removes useful path-template guidance from the skills.
   - Confidence: medium
2. Copy artifact path templates directly into each domain-related skill
   - Pros: Keeps each skill self-contained.
   - Cons: Duplicates artifact definitions and risks drift between skills.
   - Confidence: medium
3. Remove concrete path patterns from reusable skill materials
   - Pros: Avoids reusable path templates in skill text.
   - Cons: Makes the skills less concrete for agents creating todos or specs.
   - Confidence: low

## Inconsistency: `change.md` labels `uspecs-concepts` as the object-model source of truth

Decision: Rename the reference label to neutral wording: `concepts skill (current DDD overview)`.

- Pros: Removes the source-of-truth contradiction while preserving the reference.
- Cons: Is slightly less specific about why the file matters today.
- Confidence: high

Alternatives:

1. Rename it to `concepts skill (legacy object-model rules)`
   - Pros: Makes clear the current skill contains rules that will be moved or adapted.
   - Cons: "Legacy" may overstate the status before implementation happens.
   - Confidence: medium
2. Remove the `uspecs-concepts` reference from `change.md`
   - Pros: Avoids confusing readers with the old source location.
   - Cons: Loses an important input for the planned refactor.
   - Confidence: low

## Ambiguity: reusable rules and decisions need separate homes

Decision: Keep Domain Design Specification artifact paths in shared `domain-artifacts.md`, finalized Domain-Driven Design (DDD) concepts in `uspecs-domains/SKILL.md`, and DDD rationale under a first-level header in `ddd-rationale.md`.

- Pros: Keeps rationale out of the main skill instructions while preserving discoverable reasoning for users who ask why.
- Cons: Requires multiple reusable files to stay conceptually aligned.
- Confidence: high

Alternatives:

1. Put rules and rationale together in `uspecs-domains/SKILL.md`
   - Pros: Allows tighter skill wording.
   - Cons: Makes the main skill heavier and loads rationale even when the user does not need it.
   - Confidence: medium
2. Keep a separate change-folder source draft for rules and decisions
   - Pros: Preserves an implementation history artifact.
   - Cons: Duplicates reusable materials and can drift.
   - Confidence: low

## Inconsistency: Domain Specifications include a glossary while Bounded Contexts own Ubiquitous Language

Decision: Remove Domain-level `## Glossary` from Domain Specifications; keep `context.md ## Ubiquitous Language` as the formal vocabulary artifact.

- Pros: Avoids duplicating or flattening Context-specific language in `domain.md`, and keeps vocabulary ownership aligned with Bounded Context boundaries.
- Cons: Domain readers lose a quick cross-context term list and must follow Context specs or relationship/model-alignment entries for precise language.
- Confidence: high

Alternatives:

1. Keep a Domain-level glossary only for cross-context terms
   - Pros: Gives readers a small strategic vocabulary without copying every Context's language.
   - Cons: Creates another judgment call for agents and can still blur Context-specific meanings.
   - Confidence: medium
2. Rename the Domain glossary to Shared Language or Domain Vocabulary
   - Pros: Makes the intent less tied to context-specific Ubiquitous Language.
   - Cons: Keeps a duplicate vocabulary surface and does not solve ownership drift.
   - Confidence: low
