---
change_id: 2606090717-context-and-objects-specs
type: feat
domains: [prod]
---

# Change request: Introduce context.md as the bounded context and tactical design artifact

## Why

The framework names Domain Object as Entity, Value Object, and Service, but this is only a fraction of the DDD tactical model: there is no way to capture:

- Aggregates (consistency boundaries)
- Repositories
- Factories
- Events

To capture them we need to introduce context.md which holds the authoritative definition of a bounded context, including all Tactical Design Elements. Tactical design details live inside context.md; this change does not introduce separate object specification artifacts.

## What

Background:

- Reusable `uspecs-domains` skill materials contain the finalized DDD domain/context/tactical design rules and examples

Requirements:

- Context artifact scope
  - `context.md` is the authoritative Bounded Context artifact
  - Tactical Design Elements live in `context.md`, with structural elements in `## Model specification` and behavior/lifecycle elements in `## Lifecycle and behavior`
  - Ubiquitous Language belongs in `context.md`; Domain Specifications do not include a Domain-level `## Glossary`
  - Do not introduce separate object specification files
- Skills refactoring
  - `uspecs-domains` skill should be the authoring/review skill for Domain Design Specifications, including Domain Specifications (`domain.md`) and Bounded Context Specifications (`context.md`), and should also trigger for DDD modeling assistance
  - `uspecs-domains` should organize guidance into separate Domain Specification and Bounded Context Specification sections
  - `uspecs-domains` should contain the finalized Domain-Driven Design (DDD) concepts
  - Decision/rationale content should live in a separate reference file so agents consult it only when the user asks for reasoning or background
  - Reusable rationale/reference materials should carry only stable, public DDD references; private or draft-only source links should stay out of reusable materials
  - `uspecs-concepts` should keep only a lightweight DDD overview and reference `uspecs-domains` for detailed domain/context/tactical design authoring rules and examples
  - `uspecs-sec-domains` should keep using the `## Domain specifications` section and include Bounded Context Specification todo items there alongside Domain Specification todo items
  - `uspecs-sec-domains` should include enough impact guidance to decide whether Domain Design Specification todos are needed without loading `uspecs-domains`
- Implementation details
  - The domain-related skills changed by this request may use a shared Domain Design Specification artifact definition with path templates for Domain Specification and Bounded Context Specification files
  - Path template scope is limited to the domain-related skills changed by this request; it is not a framework-wide path-handling policy

## How

Decisions:

- Treat `context.md` as the authoritative Bounded Context and tactical design artifact; Tactical Design Elements stay inside `context.md`, split between `## Model specification` for structural elements and `## Lifecycle and behavior` for behavior/lifecycle elements.
- Do not introduce separate object specification files; defer Modules; use `Event` as the canonical Tactical Design Element name.
- Make `uspecs-domains` the authoring/review skill for Domain Design Specifications, including Domain Specifications (`domain.md`) and Bounded Context Specifications (`context.md`), and the assistance skill for DDD modeling questions about domain boundaries, context boundaries, ubiquitous language, tactical design, lifecycle, and behavior.
- Keep finalized DDD concepts in `uspecs-domains/SKILL.md`, rationale in `ddd-rationale.md`, and concrete Domain Design Specification artifact path templates in the shared snippet.
- Keep `uspecs-concepts` as a lightweight DDD overview that points to `uspecs-domains` for detailed domain/context/tactical authoring rules and examples.
- Keep context todo items inside the existing `## Domain specifications` planning section as Bounded Context Specification items; give `uspecs-sec-domains` concrete impact-assessment guidance for deciding when Domain Design Specification todos are needed, and reserve `uspecs-domains` for substantive DDD modeling or specification content.
- Domain-related skills may use the shared Domain Design Specification artifact definition with path templates for Domain Specification and Bounded Context Specification files; this does not establish a framework-wide path-handling policy.
- Reusable rationale/reference materials should carry only stable, public DDD references; private or draft-only links stay out of reusable materials.
- Domain Specifications do not include a Domain-level `## Glossary`; `context.md ## Ubiquitous Language` is the formal vocabulary artifact.

Out of scope:

- Separate object specification artifacts
- Module modeling
- Framework-wide path-handling policy for unrelated skills

References:

- [clarification decisions](decisions.md)
- [shared Domain Design Specification artifacts](../../../../../.claude/skills/uspecs-concepts/shared/domain-artifacts.md)
- [current prod domain.md](../../../../../uspecs/specs/prod/domain.md)
- [domain-authoring skill](../../../../../.claude/skills/uspecs-domains/SKILL.md)
- [concepts skill (current DDD overview)](../../../../../.claude/skills/uspecs-concepts/SKILL.md)
- [domain planning-section skill](../../../../../.claude/skills/uspecs-sec-domains/SKILL.md)
- [DDD glossary](https://ddd-practitioners.com/home/glossary/)
- [Tactical Design glossary](https://ddd-practitioners.com/home/glossary/domain-driven-design/tactical-design/)
- [Bounded Context Canvas](https://dddtoolbox.com/bounded-context-canvas)

## Construction

- [x] create: [shared/domain-artifacts.md](../../../../../.claude/skills/uspecs-concepts/shared/domain-artifacts.md)
  - shared definition for Domain Design Specification artifacts: Domain Specification and Bounded Context Specification
  - provide artifact path templates used by `uspecs-domains` and `uspecs-sec-domains`

- [x] update: [uspecs-domains/SKILL.md](../../../../../.claude/skills/uspecs-domains/SKILL.md)
  - make the skill the authoring/review guidance for Domain Design Specifications, including Domain Specifications (`domain.md`) and Bounded Context Specifications (`context.md`)
  - make the skill trigger for DDD modeling assistance, including domain/context boundaries, ubiquitous language, tactical design, lifecycle, and behavior
  - split guidance into Domain Specification and Bounded Context Specification sections
  - include finalized DDD concepts in `SKILL.md` section `## Domain-Driven Design (DDD) concepts`
  - remove Domain-level `## Glossary` from Domain Specification rules while keeping `context.md ## Ubiquitous Language`
  - include [shared/domain-artifacts.md](../../../../../.claude/skills/uspecs-concepts/shared/domain-artifacts.md) as a standalone shared snippet under `## Artifacts`
  - keep rationale out of `SKILL.md`; put it in `ddd-rationale.md`
  - include only stable, public DDD references where needed
  - use the shared artifact path templates for Domain Specification and Bounded Context Specification files
  - link to the rationale reference only for reasoning/background requests

- [x] create: [uspecs-domains/ddd-rationale.md](../../../../../.claude/skills/uspecs-domains/ddd-rationale.md)
  - reusable rationale reference for DDD decisions that should not live in the main skill instructions
  - start with first-level header `# DDD rationale`
  - append stable, public DDD references in a final `## References` section
  - keep DDD rationale in `ddd-rationale.md` section `## Decisions`
  - only stable, public DDD references; exclude private or draft-only links
  - cover the scenario where an agent is asked why the DDD/domain/context rules make a particular modeling choice

- [x] update: [uspecs-domains/example-domain.md](../../../../../.claude/skills/uspecs-domains/example-domain.md)
  - align the product-domain example with the new Domain Specification rules
  - omit Domain-level `## Glossary`
  - keep it illustrative rather than normative

- [x] update: [uspecs-domains/example-simple-devops-domain.md](../../../../../.claude/skills/uspecs-domains/example-simple-devops-domain.md)
  - align the simple DevOps-domain example with the new Domain Specification rules
  - omit Domain-level `## Glossary`
  - keep it illustrative rather than normative

- [x] update: [uspecs-domains/example-devops-domain.md](../../../../../.claude/skills/uspecs-domains/example-devops-domain.md)
  - align the detailed DevOps-domain example with the new Domain Specification rules
  - omit Domain-level `## Glossary`
  - keep it illustrative rather than normative

- [x] create: [uspecs-domains/example-context.md](../../../../../.claude/skills/uspecs-domains/example-context.md)
  - Bounded Context Specification example showing relationships, ubiquitous language, model specification, lifecycle, and behavior
  - demonstrate Tactical Design Elements inside `context.md`, with structural elements in `## Model specification` and behavior/lifecycle elements in `## Lifecycle and behavior`
  - keep it aligned with the Domain Specification examples
  - cover the scenario where an agent needs a concrete model for authoring or reviewing a new `context.md`

- [x] update: [uspecs-concepts/SKILL.md](../../../../../.claude/skills/uspecs-concepts/SKILL.md)
  - keep only a lightweight DDD overview
  - point readers to `uspecs-domains` for detailed domain/context/tactical design authoring rules and examples

- [x] update: [uspecs-sec-domains/SKILL.md](../../../../../.claude/skills/uspecs-sec-domains/SKILL.md)
  - keep using the `## Domain specifications` planning section
  - include Bounded Context Specification todo items alongside Domain Specification todo items
  - use the shared artifact path templates for Domain Specification and Bounded Context Specification files
  - include concrete impact-assessment guidance for deciding when Domain Design Specification todos are needed without loading `uspecs-domains`
