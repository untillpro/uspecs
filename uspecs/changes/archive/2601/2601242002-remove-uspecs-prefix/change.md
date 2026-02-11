---
registered_at: 2026-01-24T20:02:43Z
change_id: 260124-remove-uspecs-prefix
baseline: 70437069852e69f9c08b7b1208e354c9617bb0ae
archived_at: 2026-01-24T20:08:42Z
---

# Change request: Remove uspecs prefix from frontmatter field names

## Why

The `uspecs.` prefix in frontmatter field names (like `uspecs.registered_at`, `uspecs.change_id`) adds unnecessary verbosity without providing value. Since these fields only appear in uspecs change files, the namespace prefix is redundant. Removing it makes the frontmatter cleaner and easier to read.

## What

Update the uspecs.sh script to generate frontmatter field names without the `uspecs.` prefix:

- `uspecs.registered_at` becomes `registered_at`
- `uspecs.change_id` becomes `change_id`
- `uspecs.baseline` becomes `baseline`
- `uspecs.issue_url` becomes `issue_url`
- `uspecs.archived_at` becomes `archived_at`

Changes apply to:

- New change request creation (change frontmatter command)
- Change archiving (archive command)
