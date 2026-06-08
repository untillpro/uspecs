---
change_id: 2606081410-wrap-pr-links-backticks
type: fix
domains: [prod]
scope: [softeng]
---

# Change request: Wrap PR body same-folder links in backticks

## Why

`upr` already defangs parent-directory Markdown links in generated PR bodies, but same-folder file links such as `[current clarification decisions](decisions.md)` still render as live links. Those links are authored for the Change Folder on disk and should render inertly in PR text instead of pointing at an ambiguous or broken PR-page location.

## What

Symptom: A generated PR body leaves same-folder Markdown file links such as `[current clarification decisions](decisions.md)` unwrapped instead of rendering the literal link text in backticks.

```text
change.md includes a same-folder file link
      |
      v
cmd_action_upr extracts PR body content
      |
      v
md_defang_relative_link
      |
      v
bare filename target is skipped        <-- fault: same-folder file links stay live
      |
      v
PR body renders an unwrapped Markdown link   (symptom)
```

Corrected behavior: PR body generation wraps same-folder relative file links in backticks while preserving the existing handling for parent-directory links, absolute URLs, anchors, and fenced code blocks.

## Functional design

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: PR body link handling scenario examples to cover same-folder Markdown file targets such as `decisions.md`
  - clarify: same-folder relative file links in PR body content are rendered as inert literal Markdown by wrapping the whole `[text](path)` literal in backticks

## Construction

- [x] update: [unit/utils-md-defang.bats](../../../../../tests/unit/utils-md-defang.bats)
  - update: `PR body link handling` helper rows so `./sibling.md` and `decisions.md` assert backtick-wrapped output
  - preserve: unchanged expectations for absolute URLs, `mailto:`, anchors, root-absolute links, and fenced code blocks
  - add: supporting coverage that mixed same-folder and parent-directory links on one line are each wrapped independently

- [x] update: [sys/softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - add: `upr` PR body wiring assertion for a same-folder link such as `[current clarification decisions](decisions.md)`
  - preserve: existing assertions that fenced-code links remain untouched in `pr_body`

- [x] update: [_lib/utils.sh](../../../../../bin/_lib/utils.sh)
  - update: `md_defang_relative_link` to wrap same-folder file links while keeping their original path
  - preserve: parent-directory normalization to `/path`, multi-link handling, fenced-code skipping, and unchanged output for absolute URLs, `mailto:`, anchors, and root-absolute links
  - update: helper comments to describe the expanded same-folder behavior
