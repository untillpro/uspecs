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
  - add: scenario for projects with defined domains where the AI Agent is instructed to use relevant domain concepts and terminology while authoring the change request

## Construction

- [x] update: [softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - add: assertion coverage for uchange action output when domain specifications exist, verifying the AI Agent is instructed to use relevant domain concepts and terminology while authoring the change request

- [x] update: [artdef_change_domains.md](../../../../../bin/prompts/artdef_change_domains.md)
  - add: instruction for the AI Agent to use relevant affected-domain concepts and terminology while authoring `change.md` when domain specifications are defined
