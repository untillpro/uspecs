# DDD rationale

## Decisions

### Domain types: Business and Technical

Domains are typed `Business` or `Technical`. The work of building, delivering, and operating a product is modeled as its own Technical Domain (e.g. `devops`), not as Subdomains folded into the Business Domain it serves.

- Business Domain: the product delivered to customers (e.g. `prod`).
- Technical Domain: building, delivering, deploying, and operating the Business Domain product (e.g. `devops`).

Rationale:

- The two carry distinct Ubiquitous Languages — `Order`, `Table`, `Tariff` versus `Tenant`, `Fleet`, `Artifact`, `Release`. A Domain implies one Domain-level term set; merging forces unrelated vocabularies to share a namespace with no real overlap.
- Folder-per-Domain mirrors ownership. Technical concerns are typically owned by a platform or SRE group distinct from product teams, so the split follows Conway's law rather than fighting it.
- Classification still operates across both Domains on a single axis. Core / Supporting / Generic is always measured against business competitive advantage. In a Business Domain that advantage is direct (customer-facing); in a Technical Domain it is indirect — a capability is Core only when the business moat depends on it (cost-to-serve, delivery speed, reliability), so most Technical Subdomains are Supporting or Generic.
- The distinction is load-bearing. When the Technical Domain is folded into the Business Domain as Subdomains, the distinction does not disappear — it reappears as a `Nature` tag on each Subdomain, a split glossary, and a partition inside the Context Map. That recurrence is the evidence it is a real seam, so it is kept at the Domain level where it is cheapest to express.

Documented choice, not canon:

- Classic DDD treats technical concerns as Subdomains (usually Generic) within a Business Domain and has no Technical Domain concept as a peer of Business Domains. The Business / Technical Domain-type axis is a deliberate extension of this framework, recorded here so the choice is documented rather than an oversight.
- The purist objection: a Domain is problem space, and building or operating software is solution space, so it should not be a Domain. The counter taken here: at scale, building-and-running is a genuine problem area with its own language, actors, and investment logic, so modeling it as a Domain earns its keep. Cited sources should back the Subdomain framing; the Domain-type axis is this framework's own convention.

How to present to business:

- Do not present the Business / Technical split or the DDD documents to business stakeholders. They navigate by strategy, not by Domain taxonomy, and the Domain-type axis is an engineering-internal organizing choice invisible above the engineering boundary.
- Derive a single strategic view from both Domains: a three-column Core / Supporting / Generic map showing where competitive advantage sits (best people, richest model), where investment is deliberately kept minimal, and what is bought rather than built.
- Keep it combined, not per-Domain. The company has one strategy regardless of repository structure; splitting the view into `prod` and `devops` forces stakeholders to reassemble a picture the classification already produced.
- Surfacing Core classifications to business turns them into strategy claims. Confirm the Core calls are ones leadership would endorse — a disagreement about where the advantage lies is far more valuable surfaced on one page now than discovered later across two Domains.

### Shared Kernel excluded

The Shared Kernel pattern (two Contexts jointly owning a shared subset of the model) is not used in this framework.

- Each `context.md` owns its own Ubiquitous Language and Model specification, so a co-owned model element has no single home: it would have to be duplicated across both files (which then drift) or owned by one and referenced by the other (which is just Customer-Supplier / Published Language).
- Shared Kernel is also the most tightly coupled context-mapping pattern and is discouraged in modern DDD, trading context autonomy for shared ownership.
- Instead: publish the shared element as Published Language from one Context and consume it, or let each Context own its own copy of a small immutable Value Object (e.g. `Money`).

### Integration pattern vocabulary: service exposure and model alignment

The framework's integration-pattern vocabulary uses the relationship patterns defined above as two complementary axes: **service exposure** and **model alignment**.

The remaining classic context-mapping pattern is deliberately left out of scope for now. It is recorded here so the exclusion is a documented choice, not an omission:

- Partnership (ps): two Contexts succeed or fail together and coordinate as equals.

Rationale:

- Service exposure and model alignment answer different questions, so they are shown as separate relationship views.
- If model alignment is part of a service or integration contract, it stays with that relationship. `### Model alignment` is only for standalone model/language relationships.
- Published Language belongs on the model-alignment axis because it is the shared language being carried, not the interface shape by itself.
- Conformist and Anti-Corruption Layer are downstream model-handling stances, so they belong on the model-alignment axis rather than the service-exposure axis.

### Domain-level Glossary optional

Domain Specifications do not create a `## Glossary` section by default.

- Each Bounded Context owns its Ubiquitous Language in `context.md`, so domain-level glossary entries must not duplicate Context tactical model terms or blur Context-specific meanings.
- Domain-level vocabulary is only useful for broad framing terms shared across the domain's strategy, subdomains, capabilities, actors, or context map.
- Domain Specifications still describe shared framing through Subdomains, capabilities, external actors, and Context Maps; cross-Context language dependencies are expressed through relationship and model-alignment patterns such as Published Language.

### Context vocabulary canonicalized by the tactical model

Bounded Context Specifications do not create a separate `## Ubiquitous Language` section by default for terms already represented by tactical model elements. Existing `## Ubiquitous Language` sections may be maintained when present, especially for intentional boundary-specific terminology. The tactical model is the canonical Ubiquitous Language for named model concepts in the Context.

Decision:

- Use PascalCase model names for named tactical elements, such as `ChangeFolder`, `ReviewItem`, and `PluginInstallation`.
- Use those same names in scenarios and specifications when referring to named domain concepts.
- Avoid parallel spellings such as `Review Item` in prose and `ReviewItem` in the model.
- Preserve and maintain an existing `## Ubiquitous Language` section when the user or artifact already has one, but avoid adding duplicate entries for modeled concepts.
- Require each named domain noun to resolve to one Entity, Value Object, Aggregate, Factory, Repository, Service, Event, or an attribute of an existing model element.

Rationale:

- A generated Ubiquitous Language dictionary duplicates the Model specification once every meaningful noun must resolve to a modeled element.
- Duplicate spellings create unnecessary ambiguity for scenario alignment, implementation planning, and later source-code mapping.
- Using the model as the canonical vocabulary keeps context specs compact and makes drift visible: a term is either modeled, an attribute, or a missing model element.
- Normal English remains appropriate in explanatory prose, but named domain concepts should use the canonical model name.

Documented tradeoff:

- This is more implementation-shaped than classic prose-first DDD. The framework accepts that tradeoff because uspecs specifications are intended to align scenarios, plans, and implementation artifacts tightly.
- A separate vocabulary note is still allowed, and existing vocabulary sections remain valid, for boundary-specific terms intentionally not represented by the model. The default response should be to model the missing concept when it has identity, structure, behavior, lifecycle, or invariants.

### Entity and Value Object model organization

Bounded Context Specifications use `### Entities` and `### Value Objects` sections by default. Aggregate Roots are identified on top-level Entity headings; Entities owned by an Aggregate are nested under that Aggregate Root.

Decision:

- Use `### Entities` and `### Value Objects` as the default structural sections in `## Model specification`.
- Sort top-level Entity subsections alphabetically by Aggregate Root or independent Entity name.
- Mark Aggregate Root Entities in top-level Entity headings, e.g. `#### Order (aggregate)`.
- Nest Entities owned by an Aggregate under the Aggregate Root Entity, sorted alphabetically, e.g. `##### OrderLine`.
- Put Aggregate Root fields, invariants, state transitions, and ERD before nested owned Entity subsections.
- Describe ownership inside Entity subsections with concise lines such as `Contains:`, `Embeds:`, `References:`, and `Owned by:`.
- Sort Value Object subsections alphabetically by canonical model name.
- Include only named Value Objects that scenarios, specifications, fields, invariants, or relationship contracts need to reference directly.
- Put aggregate-local ERDs under the Aggregate Root Entity when aggregate containment would otherwise be hard to read.
- In ERDs, use `PK` only for identity-bearing Entities; do not mark Value Object fields as `PK` or `FK`.

Rationale:

- The two-section layout is easier to scan than a separate Aggregate section and avoids duplicating Aggregate Roots as both Aggregates and Entities.
- Nesting owned Entities one level under the Aggregate Root makes aggregate ownership visually explicit where it matters.
- Keeping Aggregate Root content before nested Entity subsections avoids ambiguity about whether invariants and ERDs describe the root aggregate or an owned child Entity.
- Value Objects can be scenario-facing domain language, so they deserve named sections when scenarios or specifications reference them directly, even though Value Object instances are embedded in owning model elements.
- Value Objects have no identity; ERDs may show their embedded structure, but key notation would incorrectly imply identity or independent persistence.
- Tiny embedded values that are never referenced by name can stay as fields rather than becoming separate model subsections.
- Aggregate-local ERDs still make containment visible where the boundary would otherwise be hard to read.

Rejected alternative:

- Separate `### Aggregates` plus `### Entities` duplicates the same model element when an Aggregate Root is also an Entity.
- Full aggregate-nested sections make ownership visually obvious, but they create deeper Markdown heading structures and make Value Objects harder to scan when they are scenario-facing vocabulary.
- `Standalone Value Objects` is misleading wording: the section means "named Value Objects worth defining", not objects with independent lifecycle or ownership.

### Lifecycle behavior contract threshold

Bounded Context Specifications do not create `## Lifecycle and behavior` by default. Functional Design Specifications own scenario/application behavior; Context Specifications keep lifecycle elements only when they are part of a domain contract.

Decision:

- Model Events only when they are used across Contexts or Relationships, such as integration contracts, published languages, event channels, or important cross-context lifecycle signals.
- Model Services only when they are part of a stable domain, API, or integration contract, or a cross-model domain capability that other specifications depend on.
- Model Factories only when creation semantics are part of a domain contract; otherwise document creation invariants under the relevant Entity or Aggregate when needed.
- Model Repositories only when access or persistence semantics are part of a domain contract; otherwise document aggregate access constraints under the relevant Aggregate when needed, and leave storage details to Technical Design or implementation.
- Document invariants and state transitions under the relevant Entity, especially the Aggregate Root Entity for aggregate-wide rules, when they define allowed model states across scenarios.

Rationale:

- Scenario/application actions such as `CreateChangeRequest` are Features; duplicating them as Services in `context.md` creates a second behavioral specification that drifts from Gherkin.
- Events, Services, Factories, and Repositories can still be tactical model elements, but only when they are part of a domain contract rather than just workflow steps, implementation structure, or storage mechanics.
- Invariants and state transitions are model truths, so they belong beside the model element they constrain rather than in a global behavior section.

### Relationship map scope

Domain-level relationship maps summarize relationships between Bounded Contexts. External actors remain in the domain's `External actors` section and are absent from domain-level relationship maps and indexes.

Context-level relationship maps describe the focal Context's direct collaboration surface. They may include Bounded Contexts, roles, and external systems when those actors directly provide or consume the focal Context's service or integration contracts. Roles and systems can both consume protected contracts; authorization details belong in the relationship entry when relevant.

## References

- [Domain-driven Design: A Practitioner's Guide: Glossary](https://ddd-practitioners.com/home/glossary/)
- [Tactical Design](https://ddd-practitioners.com/home/glossary/domain-driven-design/tactical-design/)
- [The difference between domains, subdomains and bounded contexts](https://ddd-practitioners.com/2023/03/07/the-difference-between-domains-subdomains-and-bounded-contexts/)
- [Context Map](https://ddd-practitioners.com/home/glossary/context-map/)
- [Bounded Context Canvas](https://dddtoolbox.com/bounded-context-canvas)
