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

### Domain-level Glossary excluded

Domain Specifications do not include a `## Glossary` section.

- Each Bounded Context owns its Ubiquitous Language in `context.md`, so domain-level glossary entries either duplicate Context language, blur Context-specific meanings, or become too generic to guide modeling.
- Domain Specifications still describe shared framing through Subdomains, capabilities, external actors, and Context Maps; cross-Context language dependencies are expressed through relationship and model-alignment patterns such as Published Language.

### Relationship map scope

Domain-level relationship maps summarize relationships between Bounded Contexts. External actors remain in the domain's `External actors` section and are absent from domain-level relationship maps and indexes.

Context-level relationship maps describe the focal Context's direct collaboration surface. They may include Bounded Contexts, roles, and external systems when those actors directly provide or consume the focal Context's service or integration contracts. Roles and systems can both consume protected contracts; authorization details belong in the relationship entry when relevant.

## References

- [Domain-driven Design: A Practitioner's Guide: Glossary](https://ddd-practitioners.com/home/glossary/)
- [Tactical Design](https://ddd-practitioners.com/home/glossary/domain-driven-design/tactical-design/)
- [The difference between domains, subdomains and bounded contexts](https://ddd-practitioners.com/2023/03/07/the-difference-between-domains-subdomains-and-bounded-contexts/)
- [Context Map](https://ddd-practitioners.com/home/glossary/context-map/)
- [Bounded Context Canvas](https://dddtoolbox.com/bounded-context-canvas)
