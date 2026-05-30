# Change domains and scope frontmatter

## data

- Scan `uspecs/specs/*/domain.md`
- If the change input is ambiguous, use best-effort inference from discovered domain directory names and affected domain specifications
- When authoring `change.md`, use relevant concepts and terminology from the affected domain specifications
- Do not ask the Engineer to choose affected domains during change creation

For `domains`:

- If no domain specification files exist, omit the `domains` frontmatter field
- If domain specification files exist, set `domains` in `change.md` frontmatter to a YAML flow list of affected domain directory names, e.g. `domains: [prod]` or `domains: [prod, devops]`
- Derive valid domain names from the directory segment matched by `uspecs/specs/{domain}/domain.md`; do not use display names, paths, spec file names, or file extensions

For `scope`:

- If no domain specification files exist, omit the `scope` frontmatter field
- Infer `scope` only after affected domains are inferred
- Infer affected contexts from the contexts listed under `## Contexts` in affected `uspecs/specs/{domain}/domain.md` files
- If affected contexts can be inferred confidently, set `scope` in `change.md` frontmatter to a YAML flow list
- Use unqualified context names for scope entries when context names are unique across affected domains, e.g. `scope: [softeng]`
- When affected domains contain duplicate context names that would make a scope entry ambiguous, use `domain/context` entries for those duplicate names, e.g. `scope: [prod/ops, devops/ops]`
- If no affected context can be inferred confidently, omit the `scope` frontmatter field
