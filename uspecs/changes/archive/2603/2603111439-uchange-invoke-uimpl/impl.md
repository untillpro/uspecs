# Implementation plan: uchange invokes uimpl by default

## Functional design

- [x] update: [softeng/uchange.feature](../../../../specs/prod/softeng/uchange.feature)
  - add: Scenario "Create change request" covering default uimpl invocation and --no-impl skip behaviour

## Construction

- [x] update: [u/actn-uchange.md](../../../../u/actn-uchange.md)
  - add: `--no-impl` parameter to Input parameters list
  - update: last step in Flow - after showing the user what was created, invoke `uimpl` action by default unless `--no-impl` flag is provided

## Quick start

Default (uimpl runs automatically after change is created):

```text
uchange my new feature
```

Skip uimpl:

```text
uchange my new feature --no-impl
```
