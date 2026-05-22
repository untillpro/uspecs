---
registered_at: 2026-05-22T09:31:26Z
change_id: 2605220931-upr-emit-first-two-sections
type: fix
scope: softeng
baseline: 58dba9d68a337bf87abe143e4197f0e06f1609fb
issue_url: https://github.com/untillpro/uspecs/issues/105
archived_at: 2026-05-22T10:58:19Z
---

# Change request: upr emits first two change sections into PR body

Refs:

- [105: upr: emit first two sections of change.md into PR body](./issue-105.md)

## Why

`upr` currently builds PR descriptions by looking for specific `change.md` section names. When a change request uses `## How` or another second section instead of `## What`, useful reviewer context is omitted from the PR body.

## What

Deliver a fix to the PR body generation behavior:

- Symptom: PR bodies can contain only the frontmatter and `## Why`, dropping the next reviewer-relevant section when it is not named `## What`.
- Flow: the `upr` action reads `change.md`, the PR body assembler selects sections by recognized heading names, the heading-name filter rejects a valid second `##` section such as `## How`, and `gh pr create` receives an incomplete body.
- Corrected behavior: `upr` emits the frontmatter followed by the first two top-level `##` sections from `change.md`, regardless of those section headings, while preserving the existing body-size guards.

## How

Decisions:

- Update the `upr` PR body assembly to count top-level `##` sections instead of requiring `## Why` and `## What` names.
- Use one uniform rule for all change body shapes: after frontmatter, emit the first two top-level `##` sections rather than keeping a separate `## Context` mode.
- Keep the details note when additional top-level sections are omitted, and format file references in that note as Markdown links.
- Preserve the current frontmatter formatting and body-size truncation behavior: after section selection, truncate at 40 lines or 4000 characters, whichever is reached first.
- Cover both the reported `## Why` plus `## How` case and the omitted-third-section details note in the `upr` system tests.

References:

- [upr action implementation](../../../../../bin/softeng.sh)
- [upr system tests](../../../../../tests/sys/softeng.sh-action-upr.bats)

## Functional design

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: "Construct PR body" examples so `pr_body` is composed from frontmatter followed by at most the first two top-level `##` sections of `change.md`, regardless of section headings
  - update: "Construct PR body" rules so the section limit and size limits are stated separately: at most two top-level sections, then truncate at 40 lines or 4000 characters, whichever is reached first
  - add: example for `## Why` followed by `## How`, asserting both sections are included
  - add: example for a third top-level section, asserting it is omitted and the details note links to `change.md`

## Construction

- [x] update: [softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - update: PR body helper comments and assertions to describe first-two-section selection instead of requiring specific `## Context` / `## Why` / `## What` heading names
  - update: existing PR body tests that currently expect `## How` to be filtered out so `## How` is included when it is one of the first two top-level sections
  - add: coverage for a third top-level `##` section being omitted with `See [change.md](change.md) for details.`

- [x] update: [softeng.sh](../../../../../bin/softeng.sh)
  - update: `cmd_action_upr` PR body assembly to emit frontmatter followed by at most the first two top-level `##` sections after the main heading, regardless of section names
  - update: omitted-section details note to use the Markdown link `See [change.md](change.md) for details.`
  - preserve: after section selection, keep the existing 40-line and 4000-character truncation guards with the current truncation notice
