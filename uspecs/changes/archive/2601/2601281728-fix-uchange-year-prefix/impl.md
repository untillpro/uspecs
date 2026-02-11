# Implementation plan: Fix uchange year prefix to use correct current year

## Construction

- [x] update: `[uspecs/u/conf.md](../../u/conf.md)`
  - Expand Change Folder naming format definition in Artifacts section
  - Document YYMMDD format specification: YY (2-digit year), MM (2-digit month), DD (2-digit day)
  - Add example: For 2026-01-28, use prefix "260128"
  - Add change-name format specification: kebab-case, under 40 chars (ideal: 15-30), focus on core action
  - Provide examples and abbreviation guidance
  - This is the authoritative definition that actn-changes.md already references

## Quick start

When creating a new change, the AI Agent will now follow explicit date formatting rules:

- Extract current date from system prompt (e.g., "The current date is 2026-01-28")
- Format as YYMMDD: year 2026 -> "26", month 01 -> "01", day 28 -> "28"
- Result: "260128-change-name"

Example for creating a change on 2026-01-28:

```text
uchange fix validation bug
```

Creates folder: `uspecs/changes/260128-fix-validation-bug/`
