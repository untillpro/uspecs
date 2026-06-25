---
name: uspecs-domains
description: Use this skill when authoring or reviewing Domain Design Specifications, including Domain Specifications (domain.md) and Bounded Context Specifications (context.md), or when assisting with substantive DDD modeling, domain and bounded context boundaries, ubiquitous language, tactical design elements, lifecycle, and behavior.
user-invocable: false
---

## Artifacts

[Domain Design Specification artifacts](../uspecs-concepts/shared/domain-artifacts.md)

## Domain Specification guidance

Use the `Domain` and `Subdomain` rules in `## Domain-Driven Design (DDD) concepts` when authoring or reviewing `domain.md`.

## Bounded Context Specification guidance

Use the `Bounded Context (Context)`, relationship, Tactical Design Elements, and Feature rules in `## Domain-Driven Design (DDD) concepts` when authoring or reviewing `context.md`.

## Domain-Driven Design (DDD) concepts

- `Domain`
  - Target subject area of a computer system (product)
  - Strategic, problem space
  - Type: Business | Technical
    - Business Domain: the product delivered to customers
    - Technical Domain: building, delivering, deploying, and operating the Business Domain product
  - Identified by its folder name; example domains are `prod` and `devops`
    - `prod`: Business Domain. The business logic and customer-facing capabilities - what the product does for its users
    - `devops`: Technical Domain. Building, delivering, deploying, and operating the Business Domain product — development, testing, artifact delivery, deployment, and operations (monitoring, observability, incident response)
  - Title: `# Domain: {slug}`, e.g. `# Domain: prod`
  - Describes
    - Executive summary
      - Scope
      - Out of scope
    - Subdomains
      - One subsection per subdomain: `### {Name} ({Type})`, where type is `Core`, `Supporting`, or `Generic`
      - Each subdomain subsection contains a short purpose statement
      - Each subdomain subsection contains a capability table with columns `Capability` and `Bounded Context(s)`
    - External actors
      - Roles are actor categories defined by the domain's Bounded Contexts, e.g. RBAC roles such as `Shopper` or `Support Agent`
      - Systems are external non-role actors outside the Bounded Context boundary, such as software services, devices, platforms, or infrastructure
      - Roles and systems may be authorized through RBAC, scopes, claims, service accounts, mTLS identities, or other access-control mechanisms
      - Generic consumers such as `API consumers` are avoided when a role or system boundary is known
    - Bounded Contexts
      - Context list
        - Links to each Bounded Context and a short purpose summary
      - `### Service exposure`
        - Mermaid graph of service exposure relationships
      - `### Service exposure index`
        - Table columns: `Upstream`, `Downstream`, `Contract`, `Exposure`, `Alignment`
        - `Alignment` contains the model-alignment stance carried by the service or integration contract, when present
      - `### Model alignment`
        - Mermaid graph of standalone model alignment relationships
      - `### Model alignment index`
        - Table columns: `Upstream`, `Downstream`, `Model/language`, `Alignment`
        - Contains standalone model/language relationships only
      - Relationship index tables
        - Rows sorted by `Upstream`
        - Full pattern names, e.g. `Open Host Service`, `Published Language`, `Conformist`, `Anti-Corruption Layer`
      - Relationship graphs follow `Relationship graph rules`
      - Domain-level Context Maps and relationship indexes contain Bounded Contexts only; external actors stay in `External actors`

- `Subdomain`: a distinct part of the problem space within a Domain
  - Type: Core | Supporting | Generic — a statement of business value, evaluated independently of the software design, that drives build-vs-buy and staffing
    - Core Subdomain: provides the organization's competitive advantage and strategic value; built in-house with the best people and the richest model, and evolved continuously
    - Supporting Subdomain: necessary for the business and supports the Core, but not a competitive differentiator; built, but with minimal investment
    - Generic Subdomain: common functionality not specific to the business; acquired, adopted off-the-shelf, or reused rather than built as a strategic asset
    - Classification is always measured against business competitive advantage, regardless of the parent Domain's type: in a Business Domain advantage is direct (customer-facing); in a Technical Domain it is indirect — Core only where the business moat depends on the capability, so most Technical Subdomains are Supporting or Generic
  - Delivers one or more capabilities, each realized by one or more Bounded Contexts — a Subdomain-to-Context relationship that is many-to-many

- `Bounded Context (Context)`: a model boundary in the solution space, with a specific set of actors, concepts, operations, and rules, realizing one or more Subdomains
  - Primary indicators
    - Low coupling to other Contexts
    - Autonomy of evolution (components evolve independently)
    - Team/organizational responsibility
    - Data autonomy
    - A concept with its own lifecycle and model can be a separate Context; if it is only an attribute or target name, it normally belongs inside the Context that uses it
  - Naming: noun (normally plural) or noun phrase
    - Examples: `payments`, `reviews`
  - Title: `# Bounded Context: {slug}`, e.g. `# Bounded Context: checkout`
  - Solution space, both strategic (boundary, Ubiquitous Language) and tactical (the model that realizes it)
  - Describes
    - Executive summary
      - Scope
      - Out of scope
    - External actors
    - `## Relationships` section
      - Relationship graphs follow `Relationship graph rules`
      - Relationship entries follow `Relationship documentation`
    - `## Ubiquitous Language` section
      - The specific, unambiguous dictionary of core nouns and verbs used exclusively within this boundary. Avoid duplicating with Tactical Design Elements
    - Tactical Design Elements stay inside `context.md`: structural elements are documented in `## Model specification`; behavior and lifecycle elements are documented in `## Lifecycle and behavior`
    - `## Model specification` section
      - Entities, Value Objects, Aggregates; include a subsection only when objects of that kind exist
      - Each object subsection may include a field table with `Field`, `Type`, and `Description` columns
      - ERD shows structural fields only; full field semantics live in object subsections
        - Structural fields: identifiers, references, lifecycle state, relationship-bearing fields, aggregate-boundary fields, and invariant-bearing fields
    - `## Lifecycle and behavior` section
      - Factories, Repositories, Services, Events

- `Relationship views`
  - `Service exposure`
    - A runtime or exchange contract exposed by an upstream/provider and consumed by downstream actors or Contexts
    - Examples include UIs, request/response APIs, commands, queries, event/message channels, feeds, exports/imports, files, streams, and external system interfaces
    - Diagram edge styles: `--->` for Open Host Service; `-..->` for Customer-Supplier
    - Service exposure may carry model alignment; that alignment stays with the service exposure relationship
    - `Open Host Service (ohs)`: upstream exposes a public, general-purpose contract for many consumers
    - `Customer-Supplier (c/s)`: upstream provides a contract tailored to one or a few known downstream consumers
  - `Model alignment`
    - A standalone relationship about how one Context depends on, adopts, or translates another Context's language/model
    - Scope: model/language dependencies not carried by a service or integration contract, such as reference terminology, conceptual models, shared classification schemes, or design-time schemas that are not themselves an exchange contract
    - Diagram edge styles: `===>` for Published Language; `--->` for Conformist; `-..->` for Anti-Corruption Layer
    - `Published Language (pl)`: upstream publishes a documented, versioned language/model
    - `Conformist (cf)`: downstream adopts the upstream model as-is, without the upstream publishing a separate formal language for this relationship
    - `Anti-Corruption Layer (acl)`: downstream translates the upstream model into its own model

- `Relationship graph rules`
  - Apply to Domain-level Context Maps and Context-level `## Relationships`
  - Arrows point upstream -> downstream
  - Edge labels are short noun phrases, at most three words, identifying the carried concept or contract
  - Edge labels do not include pattern suffixes
  - Edge styles encode relationship patterns

- `Relationship documentation`
  - Applies to Context-level detailed relationship entries
  - Context-level relationship views cover Bounded Contexts, roles, and external systems that directly provide or consume the focal Context's contracts
  - Sections: `### Service exposure`, `### Model alignment`
  - Each section includes
    - Mermaid graph following `Relationship graph rules`; the focal Context has a distinct node shape
    - Detail subsections for relationships documented in that section
      - Entry order in a Context: incoming relationships first, sorted by upstream name; outgoing/provider relationships second, sorted by downstream name or by provided contract name for one-to-many contracts
  - Detail subsections
    - Headings
      - `#### {upstream} -> {downstream}: {carried concept} ({pattern})`
      - `#### {provider}: {provided interface, language, or model} ({pattern})` for one-to-many provided contracts
      - Pattern suffix
        - Service only: one service exposure pattern in a relationship detail heading under `### Service exposure`, e.g. `(ohs)`, `(c/s)`
        - Service plus model alignment: a composed suffix in a single relationship detail heading under `### Service exposure`, e.g. `(ohs + pl)`, `(ohs + cf)`, `(ohs + acl)`, or the same model suffixes with `c/s`
        - Standalone model alignment: one model-alignment pattern in a relationship detail heading under `### Model alignment`, e.g. `(pl)`, `(cf)`, `(acl)`; only for model/language relationships not carried by a service or integration contract
          - Example: `#### catalog -> search: product classification (acl)`
            - `search` uses `catalog`'s product classification language as a reference model but translates it into local `SearchFacet` and `SearchIndexCategory` concepts
            - No API, event/message channel, feed, export/import, file, or other exchange contract is exposed for this relationship
    - Canonical cross-context details live with the artifact being made canonical:
      - Exposed service or integration contract details live in the upstream/provider Context
      - Published Language (`pl`) details live in the upstream/provider Context
      - Conformist (`cf`) model-alignment details live in the downstream Context that conforms:
        - For service-backed relationships such as `(ohs + cf)` or `(c/s + cf)`, the upstream/provider Context owns the canonical service or integration contract details; the downstream owns its local conformity notes
        - For standalone Conformist (`cf`) model alignment, the upstream should list known downstream conformists, but the detailed relationship entry lives downstream because the upstream publishes no separate formal language for that relationship
      - If the provider is external and has no Context spec, the consuming Context owns local adaptation or translation notes and links to the external provider reference
    - Consumers keep summaries, local conformity/adaptation notes, and links to the provider Context or external provider reference
  - A model stance already described as part of a service exposure relationship has no separate `### Model alignment` entry

- `Tactical Design Elements`
  - `Entity`: has identity and lifecycle (e.g., User, Order, Article)
  - `Value Object`: defined by attributes, immutable, no identity (e.g., Address, Money)
  - `Aggregate`: a cluster of entities and value objects treated as a single consistency boundary; external references point only at its `Aggregate Root`, which enforces the aggregate's invariants
  - `Service`: encapsulates domain operations that span multiple objects and belong to no single entity or value object
  - `Event`: a meaningful occurrence in the domain, modeled as an immutable object (e.g., OrderPlaced)
  - `Repository`: provides collection-like lookup and persistence for Aggregate Roots, hiding storage details
  - `Factory`: encapsulates complex creation of aggregates or entities so their invariants hold from creation

- `Feature`: cohesive set of scenarios within a Context
  - Single object: operations on the same object
  - Cross-object: related operations across multiple objects (workflow)
  - Can involve multiple actors
  - Context contains features, feature belongs to exactly one Context
  - Context defines the nouns (entities); feature defines the behavior over them (actions/verbs)

## Examples

- [Domain example: prod](./example-domain.md) - product/business domain with several Bounded Contexts
- [Domain example: simple DevOps](./example-simple-devops-domain.md) - simple greenfield technical domain
- [Domain example: detailed DevOps](./example-devops-domain.md) - illustrative technical domain for deriving Domain Design Specifications from source, platform, or operations evidence; real codebases may reveal different boundaries and patterns
- [Bounded Context example](./example-context.md) - Bounded Context with relationships, Ubiquitous Language, model specification, lifecycle, and behavior

## Rationale

Consult [ddd-rationale.md](./ddd-rationale.md) only when the user asks for reasoning or background behind the DDD choices above.
