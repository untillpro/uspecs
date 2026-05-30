---
change_id: 2605301806-uchange-use-domain-terms
type: fix
domains: [prod]
scope: [softeng]
---

# Change request: Domain terminology in uchange prompts

## Why

Domain specifications define the concepts and terminology that should shape uspecs artifacts. When `uchange` creates a change request in a project with defined domains, the agent should use those domain concepts and terms so the resulting artifact stays aligned with the project's specification language.

## What

Symptom: Change requests created by `uchange` can ignore available domain concepts and terminology even when domain specifications are defined.

```text
Engineer invokes uchange
      |
      v
uchange action instructions
      |
      v
domain discovery guidance
      |
      v
change request authoring guidance   <-- fault: does not instruct the agent to use domain concepts and terminology
      |
      v
change.md may use generic or inconsistent language   (symptom)
```

Corrected behavior: When domain specifications are defined, `uchange` instructs the agent to use relevant domain concepts and terminology while authoring the change request.

## Functional design

- [x] update: [../../specs/prod/softeng/uchange.feature](../../../../specs/prod/softeng/uchange.feature)
  - update: domain frontmatter scenario to require `domains` as a YAML flow list
  - add: scenario for projects with defined domains where the AI Agent is instructed to use relevant domain concepts and terminology while authoring the change request

- [x] update: [../../specs/prod/softeng/uimpl.feature](../../../../specs/prod/softeng/uimpl.feature)
  - update: Construction section behavior to describe `scope:` as a YAML flow list

- [x] update: [../../specs/prod/softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: PR subject examples to cover YAML flow-list scopes
  - preserve: legacy scalar scope example for backwards-compatible PR subject construction

## Construction

- [x] update: [softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - add: assertion coverage for uchange action output when domain specifications exist, verifying YAML flow-list `domains` guidance and domain terminology guidance

- [x] update: [softeng.sh-action-uimpl.bats](../../../../../tests/sys/softeng.sh-action-uimpl.bats)
  - add: assertion coverage for generated `scope:` guidance using YAML flow-list examples

- [x] update: [softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - add: assertion coverage for YAML flow-list scopes in PR subjects
  - add: regression coverage for legacy comma-separated scalar scopes

- [x] update: [artdef_change_domains.md](../../../../../bin/prompts/artdef_change_domains.md)
  - update: `domains` frontmatter guidance to use YAML flow-list format
  - add: instruction for the AI Agent to use relevant affected-domain concepts and terminology while authoring `change.md` when domain specifications are defined

- [x] update: [include_impl_sections.md](../../../../../bin/prompts/include_impl_sections.md)
  - update: Construction section `scope:` guidance to use YAML flow-list format

- [x] update: [softeng.sh](../../../../../bin/softeng.sh)
  - add: `normalize_change_scope` helper that strips flow-list brackets and whitespace
  - update: `upr` subject construction to normalize `scope:` before composing the Conventional Commit subject
