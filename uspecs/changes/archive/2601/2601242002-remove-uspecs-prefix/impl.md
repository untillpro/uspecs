# Implementation plan: Remove uspecs prefix from frontmatter field names

## Construction

- [x] update: `[uspecs/u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)`
  - Line 120: change `uspecs.registered_at:` to `registered_at:`
  - Line 121: change `uspecs.change_id:` to `change_id:`
  - Line 124: change `uspecs.baseline:` to `baseline:`
  - Line 128: change `uspecs.issue_url:` to `issue_url:`
  - Line 241: change `uspecs.archived_at:` to `archived_at:`

## Quick start

Add frontmatter to a new change:

```bash
bash uspecs/u/scripts/uspecs.sh change frontmatter uspecs/changes/260124-my-change/change.md
```

The generated frontmatter will now use clean field names:

```yaml
---
registered_at: 2026-01-24T20:02:43Z
change_id: 260124-my-change
baseline: 70437069852e69f9c08b7b1208e354c9617bb0ae
---
```

Archive a change:

```bash
bash uspecs/u/scripts/uspecs.sh change archive uspecs/changes/260124-my-change
```

The archived_at field will be added without the uspecs prefix:

```yaml
---
registered_at: 2026-01-24T20:02:43Z
change_id: 260124-my-change
baseline: 70437069852e69f9c08b7b1208e354c9617bb0ae
archived_at: 2026-01-24T20:15:30Z
---
```
