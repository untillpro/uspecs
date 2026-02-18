---
registered_at: 2026-02-18T16:43:05Z
change_id: 2602181642-rename-mgmt-to-conf
baseline: 1987769ee1d49a594d182abedac9c559ae4091e1
---

# Change request: Rename mgmt to conf and invocation type to invocation method

## Why

The term `mgmt` is ambiguous shorthand and `manage` is too broad. Renaming to `conf` better reflects the configuration nature of the context. The term "invocation type" mixes concerns - "type" suggests classification while "method" better describes how the engineer interacts with uspecs.

## What

Rename terminology across specs and internal files:

- Rename context folder and all references from `mgmt` to `conf`
- Rename `manage` / `management` to `conf` / `configuration` where used as context name
- Rename concept "Invocation Type" to "Invocation Method"
- Update all files that reference these terms
