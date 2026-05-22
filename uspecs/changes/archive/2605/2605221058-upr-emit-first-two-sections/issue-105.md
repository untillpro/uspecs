# upr: emit first two sections of change.md into PR body

- URL: https://github.com/untillpro/uspecs/issues/105
- ID: #105
- State: open
- Author: @maxim-ge (Maxim Geraskin)
- Labels: none
- Assignees: none

## Why

`upr` builds the PR body by selecting sections from `change.md` by name (`## Why` and `## What`). When a change request uses a different second section — for example `## How` instead of `## What` — that section is dropped from the PR body, and reviewers see only the `## Why` paragraph.

Example: PR #104 (`feat(softeng): Detect skill/plugin root as cwd in softeng [102]`). The change request has `## Why` followed by `## How` (no `## What`), so the PR body contains only `## Why` even though `## How` carries the decisions and out-of-scope items the reviewer needs.

## What

Change the PR body assembly in `upr` to emit the frontmatter followed by the first two `##` sections of `change.md`, regardless of their headings. Existing body-size guards remain unchanged.
