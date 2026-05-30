# Change domains frontmatter

## data

- Scan `uspecs/specs/*/domain.md`
- If no domain specification files exist, omit the `domains` frontmatter field
- If domain specification files exist, set `domains` in `change.md` frontmatter to a YAML flow list of affected domain directory names, e.g. `domains: [prod]` or `domains: [prod, devops]`
- Derive valid domain names from the directory segment matched by `uspecs/specs/{domain}/domain.md`; do not use display names, paths, spec file names, or file extensions
- If the change input is ambiguous about affected domains, use best-effort inference from the discovered domain directory names
- When authoring `change.md`, use relevant concepts and terminology from the affected domain specifications
- Do not ask the Engineer to choose affected domains during change creation
