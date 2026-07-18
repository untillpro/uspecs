# How section

## data

Append to the Change File a `## How` section capturing new high-level implementation decisions, necessary assumptions, scope boundaries, and supporting references, in the format below:

```markdown
## How

Decisions:

- Add authentication as a middleware stage shared by all protected routes
- Use standards-based OAuth 2.0 token handling instead of a custom token format
- Keep session state in shared storage so it remains available across application instances

Assumptions:

- Existing clients can complete the OAuth 2.0 authorization flow without a compatibility adapter

Out of scope:

- Multi-factor authentication
- Migrating existing password-based accounts

References:

- [request processing pipeline](../../../src/app.ts)
- [current authentication boundary](../../../src/middleware/auth.middleware.ts)
- [session storage configuration](../../../src/config/redis.config.ts)
- [authentication integration behavior](../../../tests/integration/auth.spec.ts)
- [OAuth 2.0 standard](https://datatracker.ietf.org/doc/html/rfc6749)
```

Rules:

- Read `change.md` and every document it references before authoring `## How`
- Do not restate statements already present in `change.md` or its referenced documents; add only implementation decisions that are new relative to those sources
- Derive decisions by following references; inspecting related code, tests, neighboring specifications, and established repository patterns; and consulting authoritative external sources when useful
- Decisions: always include the list; use `- None` when research finds no new implementation decisions
- Decisions: include high-level choices about architecture, responsibility boundaries, shared versus section-specific behavior, compatibility, dependencies, migration or rollout, and cross-cutting verification
- Decisions: include a choice when changing it would materially change multiple Construction items or the overall implementation direction
- Decisions: exclude per-file edits, symbols, exact test cases, command sequences, and ordered implementation steps; those belong in `## Construction`
- Decisions: mention a file inline only when choosing that location is itself a high-level design decision; otherwise place the supporting file under References
- Decisions: keep each item concise but decisive; state the selected approach, not a topic to investigate
- When multiple approaches remain viable, choose the best-supported approach and record residual uncertainty as an assumption
- Assumptions: always include the list; capture only unverified premises necessary for the high-level implementation strategy, and use `- None` when there are none
- Assumptions: exclude file-specific premises; resolve them during implementation or capture them in Construction
- Out of scope: include only new boundaries that a reader might reasonably assume are included but that are not already stated in `change.md` or its references; omit the section when there are none
- References: include only sources that directly support a new decision or assumption; an already-linked source may be included when it provides that traceability, and the section is omitted when there are no such sources
- Use purpose-based link text in References, not file names
- By default, use a single `References:` list with internal items first, then external. Split into `References (internal):` and `References (external):` only when both groups have 2 or more items
- Verify each internal relative link resolves to an existing file before writing. The change file is at `uspecs/changes/{change-folder}/change.md`, so links to repo-root files start with `../../../`
