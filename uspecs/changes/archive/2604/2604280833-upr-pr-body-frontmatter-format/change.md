---
registered_at: 2026-04-28T07:11:57Z
change_id: 2604280711-upr-pr-body-frontmatter-format
baseline: f8175efea7653ad7f10c4b0883328729033dc0e6
archived_at: 2026-04-28T08:33:57Z
---

# Change request: Wrap PR body frontmatter in YAML code fence

## Why

The `upr` action currently strips the YAML frontmatter `---` delimiters from `change.md` when building the PR body, leaving the field lines as plain text. This loses the visual grouping of the metadata in the rendered PR description and makes it harder to distinguish frontmatter from prose content. Wrapping the frontmatter in a fenced YAML code block restores that grouping and renders the fields as syntax-highlighted YAML on GitHub.

The current body also includes implementation-plan sections (Functional design, Construction, etc.) that are noise in a PR description. Restricting the body to the Why, What and How sections keeps the PR focused on the rationale and scope of the change, while the implementation details remain accessible via `change.md`.

## What

Update the `upr` action so the PR body preserves the frontmatter as a YAML code fence and exposes the Why, What and How sections of `change.md`:

- Replace the current stripping of `---` delimiters with a transformation that replaces the opening `---` with an opening YAML code fence and the closing `---` with a closing code fence
- Compose the PR body from the frontmatter (inside the YAML code fence) followed by the Why, What and How sections of `change.md`
- Keep the existing truncation behavior (40 lines or 4000 characters, whichever hits first) and the "(truncated -- see change.md for full details)" suffix

## Functional design

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: "No PR for current branch: PR title and commit message" scenario -- replace the `pr_body` line about stripping `---` delimiters with a description that the frontmatter is wrapped in a YAML code fence and the Why, What and How sections are included
  - update: keep the existing truncation step describing the 40-line / 4000-character limit and the "(truncated -- see change.md for full details)" suffix

## Construction

- [x] update: [tests/sys/softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - update: `_make_upr_change` helper to write `## Why`, `## What`, and `## How` sections after the title, plus a `## Functional design` section containing a sentinel string so the section-filter logic is exercised
  - update: `_assert_pr_body_format` helper -- drop the assertion that the body must not contain backticks; assert that the body contains an opening YAML code fence and a closing code fence wrapping the frontmatter field lines; assert that the sentinel from the non-Why/What/How section does not appear
  - update: PR title/commit message tests to assert that Why/What/How content appears in the body
  - update: large-body and large-chars truncation tests to produce input that still exceeds the 40-line / 4000-character limits under the new composition
- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: PR body construction in `cmd_action_upr` -- replace the `awk` that strips `---` delimiters with a transformation that emits an opening YAML code fence in place of the opening `---`, the frontmatter field lines unchanged, a closing code fence in place of the closing `---`, followed by the `## Why`, `## What`, and `## How` sections from `change.md`
  - remove: the comment block stating that fenced code blocks are incompatible with GitHub PR bodies
  - keep: the existing 40-line / 4000-character truncation and "(truncated -- see change.md for full details)" suffix
