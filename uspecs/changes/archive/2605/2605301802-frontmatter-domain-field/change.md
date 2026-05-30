---
change_id: 2605301537-frontmatter-domain-field
type: feat
scope: softeng
---
# Change request: Frontmatter domain field

## Why

Change requests should expose their affected specification domains early enough for downstream prompts and reviewers to use that metadata consistently. The change creation workflow currently needs to identify this information before emitting the default change summary.

## What

In every change authoring workflow for projects with specification domains:

- Generated change metadata identifies affected domains in a `domains` frontmatter field before the default behavior summary is composed.
- The `domains` frontmatter field contains a list of domain directory names from `uspecs/specs/{domain}/domain.md` so multi-domain changes are explicit.
- When the affected domains are not obvious from the request, the authoring workflow still emits a best-effort guessed `domains` list.
- If no domain specifications exist, generated frontmatter omits the `domains` field.
- Reviewers can assess domain blast radius from frontmatter before reading the behavior summary.

## How

Decisions:

- Add instruction to `bin/prompts/instr_uchange.md` for the AI Agent to scan `uspecs/specs/*/domain.md`, infer affected domains from the matched directory names, and add `domains` to the frontmatter before composing the default behavior summary.
- Keep `bin/softeng.sh` responsible for emitting the base `change_frontmatter` artifact and avoid making bash infer affected domains from natural-language change input.

Out of scope:

- Inferring domains when no `uspecs/specs/{domain}/domain.md` files exist.
- Using display names, paths, spec file names, or file extensions as `domains` values.
- Asking the engineer to choose affected domains during change creation.
- Letting bash infer affected domains from natural-language change input.
- Changing how `scope:` is assigned during construction planning.
- Restricting `domains` frontmatter emission to planning or specification-authoring flows.

References:

- [change creation dispatch](../../../../../bin/softeng.sh)
- [change request assembly prompt](../../../../../bin/prompts/instr_uchange.md)
- [default What section rules](../../../../../bin/prompts/artdef_change_what_default.md)
- [implementation section gates](../../../../../bin/prompts/include_impl_sections.md)

## Functional design

- [x] update: [softeng/uchange.feature](../../../../specs/prod/softeng/uchange.feature)
  - add: scenario for AI Agent instructions to scan `uspecs/specs/*/domain.md` and set `domains` frontmatter from affected discovered domain directory names

## Construction

- [x] update: [softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - add: test that rendered `uchange` instructions include domain-frontmatter guidance from `artdef_change_domains` when domain specs exist
  - add: test that domain-frontmatter instructions are omitted when no domain specs exist

- [x] update: [instr_uchange.md](../../../../../bin/prompts/instr_uchange.md)
  - reference `artdef_change_domains` before the default What section is composed, guarded by `?domains_defined`

- [x] update: [softeng.sh](../../../../../bin/softeng.sh)
  - pass `domains_defined` into `uchange` instructions outside planning flows so the `artdef_change_domains` guard works for every generated change

- [x] create: [artdef_change_domains.md](../../../../../bin/prompts/artdef_change_domains.md)
  - artifact definition for scanning `uspecs/specs/*/domain.md` and setting `domains` frontmatter from affected discovered domain directory names
  - include best-effort inference guidance when change input is ambiguous about affected domains
  - include omission rule when no domain specifications exist
