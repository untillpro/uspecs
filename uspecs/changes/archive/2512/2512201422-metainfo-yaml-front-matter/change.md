---
uspecs.registered_at: 2025-12-20T13:19:48Z
uspecs.change_id: 251220-metainfo-yaml-front-matter
uspecs.baseline: fde127aca87095e0b6b09786a4e56c7371d62d2b
uspecs.archived_at: 2025-12-20T13:36:07Z
---

# Change: Metainfo should be written in YAML front matter format

## Problem

Currently, metadata like Type and Baseline in change.md files are written as plain text lines (e.g., `- Type: behavior`). This format is not standardized and makes it harder to parse and process metadata programmatically. YAML front matter is a widely-used standard format for metadata in markdown files.

## Proposal

Create and archive change operations must use YAML front matter format for metadata in change.md files.

## Scope

Standard YAML front matter format with `---` delimiters and snake_case keys prefixed with `uspecs.` namespace.

Core metadata fields to include: registered_at, change_id, baseline.

## Implementation details

### YAML front matter format

Use standard YAML front matter format with:

- `---` delimiters at start and end
- snake_case keys with `uspecs.` prefix (e.g., `uspecs.registered_at`)
- Core fields: registered_at, change_id, baseline
- Additional metadata can be added in the body as needed

Example:
```yaml
uspecs.archived_at: 2025-12-20T13:36:07Z
---
uspecs.registered_at: 2025-12-20T13:19:48Z
uspecs.change_id: 251220-metainfo-yaml-front-matter
uspecs.baseline: fde127aca87095e0b6b09786a4e56c7371d62d2b
uspecs.archived_at: 2025-12-20T13:36:07Z
---
```

### Template update

Update the change.md template in uspecs/u/templates.md to include YAML front matter:

- Templates.md is the authoritative source for change.md structure
- Ensures all new changes follow the format automatically
- Provides single source of truth for the template

### Script modification

Modify uspecs.sh changes add script to automatically add YAML front matter:

- Centralizes format logic in one place
- Ensures consistent metadata generation
- Script handles registered_at timestamp, change_id, and baseline automatically

### Validation and error handling

Fail gracefully with clear error messages during parsing:

- Helps identify and fix format issues quickly
- Provides actionable feedback to users
- Prevents silent failures

### Migration strategy

Migrate existing change.md files on-demand when they are next modified:

- Low risk, gradual migration approach
- Avoids bulk changes that might cause merge conflicts
- Files get updated naturally over time
- No immediate action required for existing files

## Technical design

See `[design.md](design.md)` for implementation details.
