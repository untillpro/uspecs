# Technical design: YAML front matter for change metadata

## Overview

Modify uspecs.sh script to generate YAML front matter format for change.md metadata instead of plain text list format. Use sed/awk for text manipulation without external YAML parsing libraries.

## File updates

- [x] update: `[uspecs/u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)`
  - Modify cmd_changes_add function to generate YAML front matter with --- delimiters
  - Change metadata format from `- key: value` to `uspecs.key: value` within YAML block
  - Update cmd_changes_archive function to insert archived_at into existing YAML front matter

- [x] update: `[uspecs/u/templates.md](../../u/templates.md)`
  - Update change.md template to show YAML front matter format
  - Add example with --- delimiters and uspecs.* prefixed keys

## Quick start

Create new change with YAML front matter:

```bash
bash uspecs/u/scripts/uspecs.sh changes add uspecs/changes/change.tmp my-change-name
```

Archive change with YAML front matter:

```bash
bash uspecs/u/scripts/uspecs.sh changes archive uspecs/changes/251220-my-change-name
```

## References

- `[change.md](change.md)` - Original change specification
