# Implementation plan: Add --branch option to uchange command

## Functional design

- [x] update: [specs/prod/softeng/change.feature](../../specs/prod/softeng/change.feature)
  - add: Scenario for creating change request with --branch option
  - add: Branch naming convention validation

- [x] update: [u/conf.md](../../u/conf.md)
  - add: Branch naming rules for change requests in Artifacts section

## Construction

- [x] update: [u/actn-uchange.md](../../u/actn-uchange.md)
  - add: --branch option parameter to Create change section
  - add: Branch creation step in Flow after frontmatter metadata
  - add: Scenario for creating change request with --branch option

## Quick start

Create change request with automatic branch creation:

```bash
uchange "Add new feature" --branch
```

Create change request without branch:

```bash
uchange "Add new feature"
```
