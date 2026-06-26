# Implementation sections menu

<!-- markdownlint-disable-->

## data
For each section below, in order:

- Consult the required skill's "Use when" / "Do not use when" rules.
- If the section does NOT apply: append nothing (no heading, no "Not applicable" line) and continue to the next section.
- If the section applies: append it and stop immediately; do not process any later sections.

Sections:

- Domain design section. Required skill: uspecs-sec-domains (?domains_maybe)
- Functional design section. Required skill: uspecs-sec-fd (?fd_maybe)
- Provisioning and configuration section. Required skill: uspecs-sec-prov (?prov_maybe)
- Technical design section. Required skill: uspecs-sec-td (?td_maybe)
- Construction and Quick start sections. Required skill: uspecs-sec-constr (?constr_maybe)
  - Set `change.md` frontmatter `scope:` from the contexts listed under `## Contexts` in `uspecs/specs/{domain}/domain.md` that the items touch, as a YAML flow list (e.g. `scope: [softeng]` or `scope: [softeng, conf]`); omit when none applies (?constr_maybe)(?domains_defined)
  - Set `change.md` frontmatter `scope:` as a short free-form name from the code area touched, as a YAML flow list (e.g. `scope: [auth]` or `scope: [auth, tests]`); omit when none applies (?constr_maybe)(?!domains_defined)
  - Set `change.md` frontmatter `breaking: true` when an existing code API / CLI / UI contract is removed or incompatibly changed; omit otherwise (additive changes are never breaking) (?constr_maybe)
