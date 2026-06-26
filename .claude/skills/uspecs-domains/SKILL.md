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

## Specification style

When creating a new Domain Design Specification, follow the style used in this skill's example Domain and Bounded Context specifications unless the task or project instructions specify a different style.

When patching an existing Domain Design Specification, preserve the existing artifact's style unless the task explicitly asks to normalize or restyle it. Preserve the artifact's current choices such as:

- actor and system markers, e.g. `👤 Engineer`, `⚙️ AI Agent`, or plain names
- context markers in diagrams or prose, e.g. `🎯 softeng`, boxed nodes, or plain names
- section names, ordering, and relationship notation
- Mermaid node labels and diagram label style
- terminology casing and display names

Do not add markers such as emojis to an existing spec that does not use them; do not remove markers from an existing spec that does use them.

When reviewing changed Domain Design Specifications, compare patched specs with their previous artifact content for accidental style drift, including actor markers, context markers, diagram notation, section shape, and display names.

## Domain-Driven Design (DDD) concepts

### Domain

Target subject area of a computer system (product).

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
    - Each subdomain subsection contains a capability table with columns `Capability` and `Realized by`
      - `Realized by` contains Bounded Context links or names that realize the capability
  - External actors
    - Roles are actor categories defined by the domain's Bounded Contexts, e.g. RBAC roles such as `Shopper` or `Support Agent`
    - Systems are external non-role actors outside the Bounded Context boundary, such as software services, devices, platforms, or infrastructure
    - Roles and systems may be authorized through RBAC, scopes, claims, service accounts, mTLS identities, or other access-control mechanisms
    - Generic consumers such as `API consumers` are avoided when a role or system boundary is known
  - Domain-level vocabulary or glossary
    - Do not create a domain-level vocabulary or glossary section by default
    - When an existing Domain spec already has one, maintain it and add broad domain-level framing terms when relevant
    - Canonical modeled concepts live in Bounded Context specifications; cross-Context language dependencies are documented through relationship and model-alignment views
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

### Subdomain

A distinct part of the problem space within a Domain.

- Type: Core | Supporting | Generic — a statement of business value, evaluated independently of the software design, that drives build-vs-buy and staffing
  - Core Subdomain: provides the organization's competitive advantage and strategic value; built in-house with the best people and the richest model, and evolved continuously
  - Supporting Subdomain: necessary for the business and supports the Core, but not a competitive differentiator; built, but with minimal investment
  - Generic Subdomain: common functionality not specific to the business; acquired, adopted off-the-shelf, or reused rather than built as a strategic asset
  - Classification is always measured against business competitive advantage, regardless of the parent Domain's type: in a Business Domain advantage is direct (customer-facing); in a Technical Domain it is indirect — Core only where the business moat depends on the capability, so most Technical Subdomains are Supporting or Generic
- Delivers one or more capabilities, each realized by one or more Bounded Contexts — a Subdomain-to-Context relationship that is many-to-many

### Bounded Context (Context)

A model boundary in the solution space, with a specific set of actors, concepts, operations, and rules, realizing one or more Subdomains

- Primary indicators
  - Low coupling to other Contexts
  - Autonomy of evolution (components evolve independently)
  - Team/organizational responsibility
  - Data autonomy
  - A concept with its own lifecycle and model can be a separate Context; if it is only an attribute or target name, it normally belongs inside the Context that uses it
- Naming: noun (normally plural) or noun phrase
  - Examples: `payments`, `reviews`
- Title: `# Bounded Context: {slug}`, e.g. `# Bounded Context: checkout`
- Solution space, both strategic (boundary) and tactical (the model and canonical vocabulary that realize it)
- Describes
  - Executive summary
    - Scope
    - Out of scope
  - External actors
  - `## Relationships` section
    - Relationship graphs follow `Relationship graph rules`
    - Relationship entries follow `Relationship documentation`
  - Vocabulary rule: the tactical model is the canonical Ubiquitous Language for the Context
    - Do not create a separate `## Ubiquitous Language` section by default
    - When an existing Context spec already has a `## Ubiquitous Language` section, maintain it and preserve the artifact's section style
    - Do not duplicate terms already represented by tactical model elements in `## Ubiquitous Language`
    - Use PascalCase model names for named tactical elements, e.g. `ChangeFolder`, `ReviewItem`, `PluginInstallation`
    - Use the same model names in scenarios and specifications when referring to named domain concepts; avoid parallel spellings such as `Review Item` and `ReviewItem`
    - Plain prose may use normal English, but a named domain noun should resolve to one Entity, Value Object, Aggregate, Factory, Repository, Service, Event, or an attribute of an existing model element
    - Add or keep vocabulary notes for boundary-specific terms that are intentionally not represented by the model; prefer adding the missing model element when the term has identity, structure, behavior, lifecycle, or invariants
  - Tactical Design Elements stay inside `context.md`: structural elements are documented in `## Model specification`; contract-relevant behavior and lifecycle elements may be documented in `## Lifecycle and behavior`
  - `## Model specification` section
    - Tactical element headings use PascalCase and are the canonical domain names for scenarios, specifications, and implementation-facing references
    - Use `### Entities` and `### Value Objects` as the default structural subsections; include a subsection only when objects of that kind exist
    - Sort top-level Entity subsections alphabetically by Aggregate Root or independent Entity name
    - Mark Aggregate Root Entities in top-level Entity headings with `(aggregate)`, e.g. `#### Order (aggregate)`
    - Document Entities owned by an Aggregate as nested subsections under the Aggregate Root Entity, sorted alphabetically, e.g. `##### OrderLine`
      - Put Aggregate Root fields, invariants, state transitions, and `ERD:` before nested owned Entity subsections
    - Describe aggregate ownership inside Entity subsections using concise ownership lines such as `Contains:`, `Embeds:`, `References:`, or `Owned by:`
    - Sort Value Object subsections alphabetically by canonical model name
    - Include only named Value Objects that scenarios, specifications, fields, invariants, or relationship contracts need to reference directly
    - Entity and Value Object subsections may include a field table with `Field`, `Type`, and `Description` columns
    - Document invariants and state transitions under the relevant Entity subsection, especially the Aggregate Root Entity for aggregate-wide rules, when they define allowed model states or impossible states across scenarios
    - Aggregate Root Entity subsections should include an `ERD:` block when the Aggregate encloses multiple model elements or when the aggregate boundary is otherwise easy to misread
      - Aggregate ERDs show only aggregate-local structure and containment/reference relationships
      - Only identity-bearing Entities may use `PK`; do not mark Value Object fields as `PK` or `FK`
      - Value Objects in ERDs are embedded structures; show embedded relationships with labels such as `embeds`
    - Context-level `### ERD`, when present, shows cross-model structure across the Context
    - ERDs show structural fields only; full field semantics live in object subsections
      - Structural fields: identifiers, references, lifecycle state, relationship-bearing fields, aggregate-boundary fields, and invariant-bearing fields
  - `## Lifecycle and behavior` section is optional; do not create it by default
    - Add it only when Factories, Repositories, Services, or Events are part of a domain contract, such as a cross-Context Relationship, exposed integration contract, Published Language, or explicitly named domain contract
    - Do not use it to restate scenario/application actions, feature workflows, or Gherkin steps

### Relationship graph rules

- Apply to Domain-level Context Maps and Context-level `## Relationships`
- Graphs are either `Service exposure` or `Model alignment`
- `Service exposure`
  - Runtime or exchange contract exposed by an upstream/provider and consumed by downstream actors or Contexts
  - Examples include UIs, request/response APIs, commands, queries, event/message channels, feeds, exports/imports, files, streams, and external system interfaces
  - May include external roles and systems
  - May carry model alignment; that alignment stays with the service exposure relationship
  - Edge styles: `--->` for Open Host Service; `-..->` for Customer-Supplier
  - `Open Host Service (ohs)`: upstream exposes a public, general-purpose contract for many consumers
  - `Customer-Supplier (c/s)`: upstream provides a contract tailored to one or a few known downstream consumers
- `Model alignment`
  - Standalone relationship about how one Context depends on, adopts, or translates another Context's language/model
  - Scope: model/language dependencies not carried by a service or integration contract, such as reference terminology, conceptual models, shared classification schemes, or design-time schemas that are not themselves an exchange contract
  - Contains Bounded Contexts only; external roles and systems stay in `External actors` and may appear in `Service exposure`
  - If an external actor's service contract carries model alignment, document that alignment in the Service exposure relationship suffix/details, e.g. `(ohs + cf)` or `(ohs + acl)`, not as a standalone Model alignment edge
  - Edge styles: `===>` for Published Language; `--->` for Conformist; `-..->` for Anti-Corruption Layer
  - `Published Language (pl)`: upstream publishes a documented, versioned language/model
  - `Conformist (cf)`: downstream adopts the upstream model as-is, without the upstream publishing a separate formal language for this relationship
  - `Anti-Corruption Layer (acl)`: downstream translates the upstream model into its own model
- Arrows point upstream -> downstream
- Edge labels are short noun phrases, at most three words, identifying the carried concept or contract
- Edge labels do not include pattern suffixes
- Edge styles encode relationship patterns

### Relationship documentation

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
          - `Upstream:` describes the published or referenced model/language
          - `Downstream:` describes local use or translation into local concepts such as `SearchFacet` and `SearchIndexCategory`
          - No API, event/message channel, feed, export/import, file, or other exchange contract is exposed for this relationship
  - Body shape
    - Do not repeat party names in body bullets when the heading already names them
    - For one-to-one relationships, use role blocks:
      - `Upstream:` for the provider or model source
      - `Downstream:` for the consumer or model user
    - For one-to-many provider contracts, use role blocks:
      - `Provider:` for the exposed service, interface, channel, language, or contract
      - `Consumers:` for each role, system, or Context consuming the contract
    - For external providers with no Context spec, put provider documentation under `Upstream:` and local adaptation or translation notes under `Downstream:`
  - Canonical cross-context details live with the artifact being made canonical:
    - Exposed service or integration contract details live in the upstream/provider Context
    - Published Language (`pl`) details live in the upstream/provider Context
    - Conformist (`cf`) model-alignment details live in the downstream Context that conforms:
      - For service-backed relationships such as `(ohs + cf)` or `(c/s + cf)`, the upstream/provider Context owns the canonical service or integration contract details; the downstream owns its local conformity notes
      - For standalone Conformist (`cf`) model alignment, the upstream should list known downstream conformists, but the detailed relationship entry lives downstream because the upstream publishes no separate formal language for that relationship
    - If the provider is external and has no Context spec, the consuming Context owns local adaptation or translation notes and links to the external provider reference
  - Consumer role blocks keep summaries, local conformity/adaptation notes, and links to the provider Context or external provider reference
- A model stance already described as part of a service exposure relationship has no separate `### Model alignment` entry

### Tactical Design Elements

- `Entity`
  - Definition: has identity and lifecycle (e.g., User, Order, Article)
  - Rule: document top-level Entities under `### Entities`, sorted alphabetically by Aggregate Root or independent Entity name; mark Aggregate Root Entities with `(aggregate)` in the heading
  - Rule: document Entities owned by an Aggregate as nested subsections under the owning Aggregate Root Entity
  - Rule: an Entity instance belongs to one Aggregate; other Aggregates reference the owning Aggregate Root identity instead of sharing the Entity instance
- `Value Object`
  - Definition: defined by attributes, immutable, no identity (e.g., Address, Money)
  - Rule: document named Value Object types under `### Value Objects`, sorted alphabetically, only when scenarios, specifications, fields, invariants, or relationship contracts need to reference them directly
- `Aggregate`
  - Definition: a cluster of Entities and Value Objects treated as a single consistency boundary; external references point only at its `Aggregate Root`, which enforces the aggregate's invariants
  - Rule: document the Aggregate on its Root Entity subsection using `(aggregate)` in the heading and ownership lines such as `Contains:`, `Embeds:`, and `References:`
  - Include an aggregate-local ERD under the Aggregate Root Entity when the boundary encloses multiple model elements or would otherwise be ambiguous
- `Service`
  - Encapsulates a domain operation that does not naturally belong to a single Entity or Value Object
  - Include only when it is part of a stable domain, API, or integration contract, or a cross-model domain capability that other specifications depend on; scenario/application actions stay in Functional Design Specifications
- `Event`
  - Immutable record of a meaningful domain occurrence
  - Include only when it is used across Contexts or Relationships, such as integration contracts, published languages, event channels, or important cross-context lifecycle signals
- `Repository`
  - Collection-like access to Aggregate Roots that hides storage details
  - Include only when access or persistence semantics are part of a domain contract; otherwise document aggregate access constraints under the relevant Aggregate when needed, and leave storage details to Technical Design or implementation
- `Factory`
  - Encapsulates complex creation of Entities or Aggregates so invariants hold from creation
  - Include only when creation semantics are part of a domain contract; otherwise document creation invariants under the relevant Entity or Aggregate when needed

### Feature

Cohesive set of scenarios within a Context.

- Single object: operations on the same object
- Cross-object: related operations across multiple objects (workflow)
- Can involve multiple actors
- Context contains features, feature belongs to exactly one Context
- Context defines the nouns (entities); feature defines the behavior over them (actions/verbs)
- Feature workflows and scenario/application actions are specified in Functional Design Specifications, not as Context `Service` elements unless they meet the Service rule above

---

## Examples

- [Domain example: prod](./example-domain.md) - product/business domain with several Bounded Contexts
- [Domain example: simple DevOps](./example-simple-devops-domain.md) - simple greenfield technical domain
- [Domain example: detailed DevOps](./example-devops-domain.md) - illustrative technical domain for deriving Domain Design Specifications from source, platform, or operations evidence; real codebases may reveal different boundaries and patterns
- [Bounded Context example](./example-context.md) - Bounded Context with relationships, model specification, and contract-relevant lifecycle elements

## Rationale

Consult [ddd-rationale.md](./ddd-rationale.md) only when the user asks for reasoning or background behind the DDD choices above.
