# How section

## data

Append to the Change File a `## How` section capturing the implementation decisions, scope boundaries, and supporting references, in the format below:

```markdown
## How

Decisions:

- Use existing middleware pipeline in `src/app.ts` to add authentication layer
- Use OAuth 2.0 library for token handling in `middleware/auth.middleware.ts`
- Store sessions in Redis (configured in `config/redis.config.ts`) for horizontal scalability

Out of scope:

- Multi-factor authentication
- Migrating existing password-based users

References:

- [application entry point](../../../src/app.ts)
- [authentication middleware](../../../src/middleware/auth.middleware.ts)
- [Redis session config](../../../src/config/redis.config.ts)
- [auth integration tests](../../../tests/integration/auth.spec.ts)
- [OAuth 2.0 RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)
```

Rules:

- Focus on decisions (choices made), not detailed design
- Keep it concise - an idea, not a full plan
- Decisions: name the choice; mention files inline only when the choice is about a specific location
- Out of scope: list items a reader might reasonably assume are included but are not; omit the section if there are none
- References: curated links supporting the change - source files referenced in Decisions, other key files related to the change (e.g., affected modules, related tests, neighboring code), and relevant external docs, RFCs, or specs; not a full inventory of files the implementation will touch
- Use purpose-based link text in References, not file names
- By default, use a single `References:` list with internal items first, then external. Split into `References (internal):` and `References (external):` only when both groups have 2 or more items
