---
registered_at: 2026-05-22T09:31:26Z
change_id: 2605220931-upr-emit-first-two-sections
type: fix
scope: softeng
baseline: 58dba9d68a337bf87abe143e4197f0e06f1609fb
issue_url: https://github.com/untillpro/uspecs/issues/105
archived_at: 2026-05-22T10:58:19Z
---

# Change request: upr emits change body sections into PR body

Refs:

- [105: upr: emit first two sections of change.md into PR body](./issue-105.md)

## Why

`upr` currently builds PR descriptions by looking for specific `change.md` section names. When a change request uses `## How` or another section name instead of `## What`, useful reviewer context is omitted from the PR body.

## What

Deliver a fix to the PR body generation behavior:

- Symptom: PR bodies can contain only the frontmatter and `## Why`, dropping the next reviewer-relevant section when it is not named `## What`.
- Flow: the `upr` action reads `change.md`, the PR body assembler selects sections by recognized heading names, the heading-name filter rejects a valid second `##` section such as `## How`, and `gh pr create` receives an incomplete body.
- Corrected behavior: `upr` emits the frontmatter followed by all body content from the first top-level `##` section in `change.md`, while preserving the existing body-size guards.

## How

Decisions:

- Update the `upr` PR body assembly to start at the first top-level `##` section and include subsequent body content regardless of heading names.
- Use one uniform rule for all change body shapes rather than keeping a separate `## Context` mode.
- Append the plain omission note only when the 40-line or 4000-character body-size guard truncates content.
- Preserve the current frontmatter formatting.
- Cover arbitrary section names, all-section inclusion while under the size limits, and truncation notes in the `upr` system tests.

References:

- [upr action implementation](../../../../../bin/softeng.sh)
- [upr system tests](../../../../../tests/sys/softeng.sh-action-upr.bats)

## Functional design

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: "Construct PR body" examples so `pr_body` is composed from frontmatter followed by all body content from the first top-level `##` section of `change.md`
  - update: "Construct PR body" rules so only the 40-line and 4000-character size limits omit content
  - add: example for `## Why` followed by `## How`, asserting both sections are included
  - update: example for a third top-level section, asserting all three sections are included when they fit

## Construction

- [x] update: [softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - update: PR body helper comments and assertions to describe all-section inclusion until size limits
  - update: existing PR body tests that currently expect later sections to be filtered out so later sections are included when under size limits
  - keep: truncation coverage for `Content omitted. See change.md for full details.`

- [x] update: [softeng.sh](../../../../../bin/softeng.sh)
  - update: `cmd_action_upr` PR body assembly to emit frontmatter followed by body content from the first top-level `##` section after the main heading
  - remove: section-count omission behavior
  - update: keep the existing 40-line and 4000-character truncation guards with the plain omission note
