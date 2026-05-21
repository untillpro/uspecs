---
registered_at: 2026-05-21T10:59:08Z
change_id: 2605211059-duplicate-what-pr-body
type: fix
baseline: 99d5fcedea93e4960b076dcd27312093148e5ad1
archived_at: 2026-05-21T11:23:18Z
---

# Change request: Prevent duplicate What content in PR bodies

## Why

`upr` builds the PR body by streaming selected sections from `change.md`. A `change.md` that contains fenced Markdown examples with `## What` headings after the real `## What` section can cause PR bodies to include later implementation or quick-start content as an extra What block, making the PR description noisy and misleading.

## What

Correct PR body extraction so the PR body includes the change-description content through the first real `## What` section and stops, adding a `See change.md for details.` note only when later `change.md` content was omitted.

Symptom: PR body includes the real `## What` section and then includes another `## What` block from a later fenced Markdown example

Flow:

```text
upr invoked for change.md
    |
    v
real ## What section is followed by ## Construction and ## Quick start
    |
    v
## Quick start contains fenced Markdown examples with ## What headings
    |
    v
bin/softeng.sh streams lines into the PR body using heading-name matching
    |
    v
FAULT: PR body filter restarts output whenever it sees any ## What heading,
        including headings inside fenced code blocks and later non-body sections
    |
    v
generated PR body contains duplicate What content
```

Corrected behavior: PR body generation includes frontmatter and all content through the first real `## What` section, appends `See change.md for details.` when later content was omitted, then stops before any later sections.

## How

Decisions:

- Update `cmd_action_upr` PR body extraction to treat the first real `## What` section as the final included body section.
- Track Markdown fenced code blocks while extracting the PR body so headings inside examples cannot restart section output.
- Append `See change.md for details.` after the emitted `## Why` + `## What` body when later `change.md` content was omitted.
- Add explicit `upr` system tests for a `change.md` containing a later fenced `## What` example after the real `## What` section.

Out of scope:

- Changing the PR body frontmatter formatting.
- Changing the existing line-count and character-count truncation limits.

References:

- [PR body extraction](../../../../../bin/softeng.sh)
- [upr system tests](../../../../../tests/sys/softeng.sh-action-upr.bats)

## Construction

- [x] update: [softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - add: `upr` PR body scenario where `change.md` has real `## Why` and `## What` sections followed by later sections containing a fenced Markdown example with another `## What` heading
  - assert: generated PR body includes the frontmatter, real `## Why`, real `## What`, and `See change.md for details.` because later sections were omitted
  - assert: generated PR body excludes later sections and the duplicate fenced-example `## What`

- [x] update: [softeng.sh](../../../../../bin/softeng.sh)
  - update: PR body extraction in `cmd_action_upr` so the first real `## What` section is the final included body section for the `## Why` + `## What` shape
  - add: fenced-code tracking so Markdown headings inside examples do not start or stop PR body sections
  - add: append `See change.md for details.` after the emitted `## Why` + `## What` body when later `change.md` content was omitted
  - preserve: existing YAML frontmatter fencing, `## Context` body-shape support, and line/character truncation limits
