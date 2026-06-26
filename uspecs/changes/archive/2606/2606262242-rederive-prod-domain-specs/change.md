---
change_id: 2606261043-rederive-prod-domain-specs
type: docs
domains: [prod]
---

# Change request: Prod domain design re-derivation

## Why

The prod domain design specification should reflect the actual AI-assisted software engineering concepts, contexts, and workflows expressed in the source material. Re-deriving it from sources helps keep the domain model useful for future specification and implementation work.

## What

Readers gain an updated domain design specification for the prod domain:

- The prod domain specification reflects the current source-derived understanding of AI-assisted software engineering workflows.
- Domain concepts, actors, contexts, and context relationships are reconciled with the available source material.
- The specification remains focused on domain design documentation, without changing product behavior.

## How

Decisions:

- Re-derive the prod domain design from existing prod specification sources under `uspecs/specs/prod`.
- Treat the current prod domain overview as the baseline to reconcile, not as immutable source text.
- Use the softeng context architecture and action feature specifications to validate actors, workflows, contexts, and relationships.

Out of scope:

- Re-deriving the devops domain design specification.
- Changing action behavior, prompts, scripts, or generated workflow output.
- Rewriting functional or technical design specifications except where needed as source references.

References:

- [prod domain overview](../../../../../uspecs/specs/prod/domain.md)
- [softeng context architecture](../../../../../uspecs/specs/prod/softeng/arch.md)
- [implementation plan workflow behavior](../../../../../uspecs/specs/prod/softeng/uimpl.feature)
- [change request workflow behavior](../../../../../uspecs/specs/prod/softeng/uchange.feature)
- [plugin lifecycle workflow behavior](../../../../../uspecs/specs/prod/conf/install.feature)

## Domain design

- [x] update: [uspecs-domains/SKILL.md](../../../../../.claude/skills/uspecs-domains/SKILL.md)
  - update: Domain Specification capability tables use `Realized by` for Bounded Context realizations
  - update: Context relationship details use `Upstream`/`Downstream` and `Provider`/`Consumers` role blocks
  - update: Context model sections use Entities and Value Objects with Aggregate Root markers and owned Entity nesting
  - update: aggregate ERD rules so Value Objects have no `PK`/`FK` notation
  - update: lifecycle behavior threshold for contract-relevant Services, Events, Factories, and Repositories

- [x] update: [ddd-rationale.md](../../../../../.claude/skills/uspecs-domains/ddd-rationale.md)
  - add: rationale for `Realized by` capability-table column naming
  - add: rationale for relationship detail role blocks
  - add: rationale for model vocabulary, Entity/Value Object organization, aggregate ERDs, and lifecycle behavior thresholds

- [x] update: [uspecs-sec-domains/SKILL.md](../../../../../.claude/skills/uspecs-sec-domains/SKILL.md)
  - update: impact detection for context vocabulary, Aggregate Root markers, owned Entity nesting, Value Objects, aggregate ERDs, fields, invariants, and contract-relevant lifecycle elements

- [x] update: [example-domain.md](../../../../../.claude/skills/uspecs-domains/example-domain.md)
  - update: Subdomain capability tables to use `Realized by`

- [x] update: [example-devops-domain.md](../../../../../.claude/skills/uspecs-domains/example-devops-domain.md)
  - update: Subdomain capability tables to use `Realized by`

- [x] update: [example-simple-devops-domain.md](../../../../../.claude/skills/uspecs-domains/example-simple-devops-domain.md)
  - update: Subdomain capability tables to use `Realized by`

- [x] update: [example-context.md](../../../../../.claude/skills/uspecs-domains/example-context.md)
  - update: relationship details to use role blocks without repeating party names
  - update: model section layout with Aggregate Root Entity marker and nested owned Entity
  - update: Value Objects section naming and ordering

- [x] update: [prod/domain.md](../../../../specs/prod/domain.md)
  - update: source-derived domain scope, external actors, concepts, contexts, and context map
  - update: context summaries for conf and softeng from available prod specification sources
  - update: Subdomain capability tables to use `Realized by`

- [x] create: [conf/context.md](../../../../specs/prod/conf/context.md)
  - Bounded Context Specification for system lifecycle management and configuration: ubiquitous language, relationships, tactical model, lifecycle, and behavior
  - update: relationship details to use role blocks without repeating party names
  - update: model section layout with Aggregate Root Entity marker and Value Objects
  - update: aggregate ERD to treat Value Objects as embedded structures without `PK`/`FK` notation

- [x] create: [softeng/context.md](../../../../specs/prod/softeng/context.md)
  - Bounded Context Specification for human-AI collaborative software engineering workflows: ubiquitous language, relationships, tactical model, lifecycle, and behavior
  - update: relationship details to use role blocks without repeating party names
  - update: model section layout with Aggregate Root Entity markers and nested owned Entities
  - update: aggregate ERD to distinguish Entity containment from embedded Value Objects
