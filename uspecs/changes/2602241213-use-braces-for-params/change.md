---
registered_at: 2026-02-24T12:13:44Z
change_id: 2602241213-use-braces-for-params
baseline: d9596c65bdadfe584c994a9bb4c5ad2d0d748d1b
---

# Change request: Use braces for parameter references

## Why

Action and template files inconsistently reference parameters using both `$param` and `{param}` styles. Standardizing on `{param}` improves readability and consistency across all uspecs documentation.

## What

Replace all `$param` style parameter references with `{param}` style in:

- All action files (`uspecs/u/actn-*.md`)
- All template files (`uspecs/u/templates/tmpl-*.md`)
- Configuration file (`uspecs/u/conf.md`)
