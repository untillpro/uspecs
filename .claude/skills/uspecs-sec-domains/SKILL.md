---
name: uspecs-sec-domains
description: Use this skill when authoring or reviewing the `## Domain design` section in `change.md` or `impl.md` files, including deciding whether Domain Design Specification todo items are needed.
user-invocable: false
---

## Domain design section

Section contains to-do items for modifying Domain Design Specifications: Domain Specifications and Bounded Context Specifications.

[Domain Design Specification artifacts](../uspecs-concepts/shared/domain-artifacts.md)

Use when the change affects domain/context actors, concepts, boundaries, relationships, vocabulary, model, lifecycle, or behavior.

Do not use when: the change only adds features, scenarios, or implementation details within an already-defined domain/context.

## Assessing Domain Design Specification impact

Decide whether Domain Design Specifications need todos from the change request and known or proposed specification names; do not load `uspecs-domains` only to make this impact check.

Add or update a Domain Specification todo when the change affects:

- domain scope or out-of-scope statements
- domain-level external actors, including actor-name casing, decorators, or the declaration-vs-reference (backtick) style
- subdomains, capabilities, or capability-to-context mapping
- an existing domain-level vocabulary/glossary section, or an explicit request to add one
- the bounded context list, context map, or domain-level relationship indexes
- creation, rename, removal, or reassignment of a bounded context

Add or update a Bounded Context Specification todo when the change affects:

- a context boundary, purpose, ownership, or external actors, including actor-name casing, decorators, or the declaration-vs-reference (backtick) style
- context relationships, service exposure, model alignment, or canonical relationship details
- context vocabulary, model term names, or an existing `## Ubiquitous Language` section
- model structure such as Entities, owned Entity nesting, Aggregate Root markers, ownership lines, Value Objects, aggregate ERDs, fields, or invariants
- context-level lifecycle or model behavior that changes the context model or a domain contract, such as contract-relevant Factories, Repositories, Services, cross-context Events, invariants, state transitions, or model rules

Do not add a Domain Design Specification todo solely to create a vocabulary/glossary or `## Ubiquitous Language` section unless the change explicitly asks for one or the target specification already maintains that section.

Do not add a Domain Design Specification todo solely to mirror feature workflows or scenario/application actions as Services or Events; those belong in Functional Design Specifications unless they also change the context model or a cross-context contract.

Do not add a Domain Design Specification todo when the change only updates feature scenarios, implementation code, tests, provisioning, or technical design within an already-defined domain and context, with no change to actors, boundaries, relationships, language, model, lifecycle, or behavior.

If the change names a likely domain/context impact but the exact modeling answer is unclear, add a targeted todo describing what must be reviewed or updated. Use `uspecs-domains` only when the current task also requires writing or reviewing the artifact content or resolving the modeling choice.

## Rules

[to-do format](../uspecs-concepts/shared/todo-format.md)
- For `create` action use a single subitem with specification type and brief domain purpose
- The domain is the first segment under `uspecs/specs/`; `domain.md` lives at `uspecs/specs/{domain}/domain.md` and contexts at `uspecs/specs/{domain}/{context}/context.md` - never add a grouping segment above the domain

## Example

```markdown
## Domain design

- [ ] create: [prod/domain.md](../../specs/prod/domain.md)
  - Domain Specification for the prod business domain: external actors, subdomains/capabilities, context list and map

- [ ] create: [prod/planning/context.md](../../specs/prod/planning/context.md)
  - Bounded Context Specification for planning: vocabulary/model terms, relationships, tactical model, and contract-relevant lifecycle elements

- [ ] update: [prod/payments/context.md](../../specs/prod/payments/context.md)
  - add: "Refund" concept with lifecycle and authorization rules
  - update: "Checkout" reference to the new Refund concept
```
