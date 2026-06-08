---
name: uspecs-sec-td
description: Use this skill when authoring or reviewing the `## Technical design` section in `change.md` or `impl.md`  files.
user-invocable: false
---

## Technical design section

Section contains to-do items for modifying technical specification files under `uspecs/specs/`:

[technical-spec artifact paths](../uspecs-concepts/shared/td-artifact-paths.md)

Use when:

- Change request modifies existing technical specifications (e.g. updating architecture or technology details)
- Change request explicitly requires creating new technical specifications or deriving technical specifications from codebase

Do not use when: the change affects only functional specifications, provisioning/configuration, or source code with no impact on architectural or technical design documentation.

## Rules

[to-do format](../uspecs-concepts/shared/todo-format.md)
- For `create` action use a single subitem with specification type and brief purpose

## Example

```markdown
## Technical design

- [ ] update: [softeng/arch.md](../../specs/prod/softeng/arch.md)
  - update: dispatch section to document uchange/uimpl action flow
  - add: new section on error handling and retry strategy
  
- [ ] create: [payments/checkout--td.md](../../specs/prod/payments/checkout--td.md)
  - Feature Technical Design: token handling, PSP integration, error recovery strategy
```
