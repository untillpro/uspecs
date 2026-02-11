---
registered_at: 2026-01-28T17:28:11Z
change_id: 260128-fix-uchange-year-prefix
baseline: 5567750c29230d53e7a304ea93eb2217b885c669
archived_at: 2026-01-28T17:41:45Z
---

# Change request: Fix uchange year prefix to use correct current year

## Why

The uchange command creates change folders with a date prefix in YYMMDD format. Currently, there appears to be an issue where the system may generate folder names with year "27" (2027) when the current year is 2026. This causes confusion and incorrect folder naming, making it difficult to track when changes were actually created.

## What

Ensure that when AI Agent creates new change folders via uchange command, the folder name uses the correct current date in YYMMDD format:

- Current date is 2026-01-28
- Folder prefix should be "260128" not "270127"
- AI Agent must use the current date from the system prompt when generating folder names
- Verify no hardcoded or incorrect date examples exist in documentation or templates

## How

Add explicit date prefix generation instructions to `uspecs/u/actn-changes.md`:

- Add new "Date prefix generation" section under "Create change (new change)"
- Document the YYMMDD format specification:
  - YY: 2-digit year (e.g., 26 for 2026, 27 for 2027)
  - MM: 2-digit month (01-12)
  - DD: 2-digit day (01-31)
- Provide concrete example: For 2026-01-28, use prefix "260128"
- Instruct AI Agent to extract current date from system prompt and format correctly

This approach is preferred because:

- No code changes to uspecs.sh required
- AI Agent already has access to current date from system prompt
- Makes documentation explicit and self-documenting
- Follows existing pattern where AI Agent creates folder and uspecs.sh validates/adds metadata
