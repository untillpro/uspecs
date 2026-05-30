---
change_id: 2605301909-frontmatter-scope-inference
type: feat
domains: [prod]
scope: [softeng]
---

# Change request: Frontmatter scope field inference

## Why

Change requests already guide the AI Agent to infer affected domains, but context-level scope still needs explicit behavior so reviewers can understand blast radius within the software engineering workflow. Inferring scope after domains keeps context names tied to the selected domain set and uses domain-qualified context names only when needed to avoid ambiguous frontmatter.

## What

In the prod domain's softeng context:

- The uchange action instructs the AI Agent to infer a scope frontmatter field after affected domains are inferred.
- Scope inference identifies affected contexts from the inferred domain set using domain terminology available to the AI Agent, using unqualified context names when they are unique.
- The AI Agent uses domain-qualified context entries when multiple affected domains would otherwise produce scope entries with the same context name.
- The AI Agent omits the scope frontmatter field when no affected context can be inferred confidently.
- Domain frontmatter inference continues to run before scope inference and remains the basis for domain-aware change request authoring.

## How

Decisions:

- Extend uchange prompt instructions so scope inference runs immediately after domain frontmatter inference.
- Define `scope` as a YAML flow list that uses unqualified context names by default and `domain/context` entries only for duplicate context-name conflicts.
- Omit `scope` when affected contexts cannot be inferred confidently from the selected domain specifications.
- Remove later construction-time scope inference so uimpl preserves scope inferred during uchange.

Out of scope:

- Rewriting existing change requests that already contain `scope`.
- Changing PR subject formatting or other consumers of the `scope` frontmatter field.

References:

- [domain frontmatter prompt](../../../bin/prompts/artdef_change_domains.md)
- [uchange creation prompt](../../../bin/prompts/instr_uchange.md)
- [implementation section scope guidance](../../../bin/prompts/include_impl_sections.md)
- [uchange behavior specification](../../../uspecs/specs/prod/softeng/uchange.feature)
- [softeng action dispatcher](../../../bin/softeng.sh)

## Functional design

- [x] update: [uchange.feature](../../specs/prod/softeng/uchange.feature)
  - update: existing domain frontmatter rule to cover scope inference after domain inference
  - add: only missing examples for duplicate context names requiring `domain/context` and omitted scope when context inference is not confident
  - preserve: existing domain inference behavior before scope inference

- [x] update: [uimpl.feature](../../specs/prod/softeng/uimpl.feature)
  - update: construction-section behavior so uimpl no longer sets `scope`
  - preserve: any existing `scope` frontmatter inferred during uchange
  - preserve: setting `breaking: true` when an existing code API, CLI, or UI contract is removed or incompatibly changed

## Construction

- [x] update: [sys/softeng.sh-action-uchange.bats](../../../tests/sys/softeng.sh-action-uchange.bats)
  - add assertions that uchange action instructions include scope inference after domain inference
  - add assertions for unique context names, duplicate context names using `domain/context`, and omitted scope when context inference is not confident
  - preserve existing domain frontmatter assertions

- [x] update: [sys/softeng.sh-action-uimpl.bats](../../../tests/sys/softeng.sh-action-uimpl.bats)
  - update construction frontmatter assertions so uimpl preserves `scope:` instead of setting it
  - preserve assertions for `breaking: true`

- [x] update: [artdef_change_domains.md](../../../bin/prompts/artdef_change_domains.md)
  - add scope frontmatter inference rules after the domain inference rules
  - define unqualified context names by default, `domain/context` for duplicate context-name conflicts, and omitted `scope` when affected context inference is not confident

- [x] update: [instr_uchange.md](../../../bin/prompts/instr_uchange.md)
  - instruct AI Agent to add or omit `scope` according to the domain and scope frontmatter rules after adding `domains`

- [x] update: [include_impl_sections.md](../../../bin/prompts/include_impl_sections.md)
  - remove construction-time `scope:` inference instructions
  - preserve construction-time `breaking: true` instructions
