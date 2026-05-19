---
registered_at: 2026-05-19T09:33:08Z
change_id: 2605190933-uchange-issue-fetch-modes
type: feat
scope: softeng
baseline: ffd8cfea960f0a8e88271b2f9aa3f3e1847a8f0c
archived_at: 2026-05-19T15:10:53Z
---

# Change request: Issue handling as a cohesive cross-action feature

## Why

Issue handling in the softeng framework is a cross-action concept: `uchange` records the URL and (used to) create `issue.md`, `upr` derives the commit subject `[<issue-id>]` and `Closes #<id>` trailer from it, and `usync` reports contradictions between implementation and `issue.md`. Today the behaviour is partially specified inside `uchange.feature` (with a fetch scenario that no longer reflects the implementation since PR #66) and the rest is implicit in `upr.feature` and `usync.feature`. This makes the feature hard to evolve and hides a regression: `uchange` no longer instructs the agent to create `issue.md`, yet downstream actions still depend on it. The framework needs one cohesive specification for issue handling and a change.md shape that recognises `issue.md` as a first-class artifact.

## What

Introduce issue handling as a dedicated functional design and align the implementation with it.

## How

- Create new functional design spec `uspecs/specs/prod/softeng/cross/issue-handling.feature` as a cross-reference hub: zero scenarios, only `Feature:` block whose description text lists each issue-related scenario across `uchange.feature`, `upr.feature`, and `usync.feature` with a one-line summary and a relative link. Scenarios themselves stay in their natural home features (branch naming with `uchange`, commit subject / `Closes` trailer with `upr`, contradiction reporting with `usync`). The new `cross/` subfolder distinguishes navigation hubs (no scenarios, only links) from the existing `shared/` subfolder (reusable scenarios that other features include via `And Examples includes examples from "..."`)

- Add a `--fetchable` boolean CLI flag to `uchange`. The AI Agent (which knows its own skills, MCP integrations, and project rules in `AGENTS.md`/`CLAUDE.md`) decides whether the issue URL is reachable and passes `--fetchable` when so. Absence of the flag means "do not fetch" (legacy shape). The flag drives both the `change.md` body shape and whether the fetch instruction is emitted. Validation: `--fetchable` requires an issue reference (otherwise error). `issue_url` is always recorded in frontmatter when provided, regardless of the flag, so `upr` continues to emit `[<issue_id>]` and `Closes #<issue_id>`

- Restore the fetch instruction in `instr_uchange.md` (lost in PR #66): conditional block emitted when `--fetchable` is passed, with canonical wording: `Fetch the issue at ${issue_url} and save it to ${change_folder}/issue.md following @artdef_issue_file.`. The block is omitted when `--fetchable` is absent. Failure handling remains the agent's responsibility and is out of scope; the artifact shape (issue.md format) is prescribed by a new artdef so that downstream tooling (notably `usync`) can rely on stable headings

- Add a new `artdef_issue_file.md` prompt artdef defining `issue.md`: H1 with the issue title, a metadata bullet list immediately after (URL, ID, State, Author, Labels, Fetched at, with optional Assignees/Milestone/Closed at/Linked PRs as additional bullets when available), followed by the issue body verbatim. If the body does not start with a markdown heading, the agent prepends `## Description`; a leading H1 in the source body is demoted to H2 to avoid a duplicate top-level heading

- `change.md` body shape now has two variants driven by `--fetchable`: without the flag (or no issue reference), the existing `## Why` + `## What` shape is kept unchanged; with `--fetchable`, `## Context` replaces `## Why` and `## What` and contains 2-3 engineer-written sentences distilling the issue followed by `See [issue.md](issue.md) for the originating ticket.` (the link is added when `issue.md` is created; if fetch fails after instruction, the engineer-written distillation alone is sufficient). The optional `## How` section (existing `--how` flag semantics) applies to both shapes

- Update `cmd_action_upr` Why/What regex to recognise `## Context` (issue-case shape, `--fetchable`) in addition to `## Why` and `## What` (non-issue case, no flag, and archived change.md files)

- Keep existing frontmatter and downstream behaviour (`extract_issue_id`, branch naming, `Closes #<id>` in commits) unchanged

## Functional design

- [x] create: [softeng/cross/issue-handling.feature](../../../../specs/prod/softeng/cross/issue-handling.feature)
  - Cross-reference hub: zero scenarios, only a `Feature: Issue handling (cross-action)` block whose description text lists each issue-related scenario across `uchange.feature`, `upr.feature`, and `usync.feature` with a one-line summary and a relative link
  - Hub lives in new `uspecs/specs/prod/softeng/cross/` subfolder reserved for navigation hubs (zero-scenario feature files that link to scenarios in their natural home features), separate from `shared/` (reusable scenarios included by other features)

- [x] update: [softeng/uchange.feature](../../../../specs/prod/softeng/uchange.feature)
  - update: `Scenario Outline: Issue reference provided` -- promote to a Scenario Outline keyed on `--fetchable` vs `(omitted)` with rows asserting (a) frontmatter records `issue_url` in both rows; (b) `## Context` body shape and fetch instruction under `--fetchable`; (c) `## Why` + `## What` body shape and no fetch instruction when the flag is omitted
  - add: validation scenario under `Rule: Edge cases` -- `--fetchable` passed without an issue reference errors out with `--fetchable requires an issue reference`

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - add: `Rule: PR artifacts` wrapping both Construct scenarios, with `Background: Given a PR is being created` factoring out the common precondition (matches the `Rule:` + `Background:` pattern in `umergepr.feature`, `usync.feature`, `uimpl.feature`)
  - rename: `Scenario Outline: No PR for current branch: PR title and commit message` -> `Scenario Outline: Construct PR title and commit message`; drop `Given no PR is associated with the current branch`, `When Engineer invokes upr action`, and the `pr_body` / `truncation` steps from it (Background covers the precondition; body steps move to the new body scenario below)
  - add: `Scenario Outline: Construct PR body` -- parameterised by change.md shape with three rows: `## Context` (issue-case shape), `## Why` + `## What` (non-issue case and archived files), and "neither section present" (frontmatter-only body); the truncation rule (40 lines / 4000 chars with "(truncated ...)") moves here

## Construction

### Tests

- [x] update: [sys/softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - add: scenario `uchange: scn: --fetchable with issue reference` -- assert frontmatter contains `issue_url`, the AGENT_INSTRUCTIONS include the fetch directive referencing `@artdef_issue_file`, the change.md body shape directive references `## Context` (not `## Why`/`## What`), and both `artdef_change_context` and `artdef_issue_file` are rendered (`artdef_change_why_what` is not)
  - add: scenario `uchange: scn: --fetchable without issue reference errors out` -- expect non-zero status and an error message containing `--fetchable requires an issue reference`
  - update: existing scenario `uchange: scn: Issue reference provided` -- without `--fetchable`, assert the AGENT_INSTRUCTIONS do NOT include the fetch directive, the body shape directive references `## Why`/`## What`, and `artdef_issue_file` is not rendered

- [x] update: [sys/softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - update: `_make_upr_change` helper to accept an optional `body_shape` parameter (`why_what` default, `context`, `none`) controlling which section(s) are written to change.md
  - add: scenario under `--- Construct PR body ---` asserting that when change.md has `## Context` (no `## Why`/`## What`), the PR body contains the rendered `## Context` content and not `SENTINEL_FILTERED_OUT`
  - add: scenario asserting that when change.md has neither `## Context` nor `## Why`/`## What`, the PR body contains only the frontmatter code block (no body sections appended)
  - update: `_assert_pr_body_format` helper to accept the expected body shape so both new scenarios and existing ones share invariants

### Implementation

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - add: `--fetchable` boolean flag parsing in `cmd_action_uchange` (no argument)
  - add: validation `--fetchable requires an issue reference` when `--fetchable` is passed without `--issue-url`
  - update: `context_vars` to include `fetchable_maybe` (set to `1` when `--fetchable` is passed) so `instr_uchange.md` conditionals can resolve it
  - update: `cmd_action_upr` pr_body awk script -- replace the regex `/^## (Why|What)[[:space:]]*$/` with `/^## (Context|Why|What)[[:space:]]*$/` so the `## Context` section is also included in the PR body alongside the existing `## Why`/`## What` recognition

- [x] update: [prompts/instr_uchange.md](../../../../../bin/prompts/instr_uchange.md)
  - replace: the single `Change request, Why and What` bullet with two conditional bullets:
    - `Change request and Context section, see @artdef_change_context (?fetchable_maybe)` -- emits the `## Context` body shape when `--fetchable` is passed
    - `Change request, Why and What, see @artdef_change_why_what (?!fetchable_maybe)` -- existing default shape when `--fetchable` is absent (use whatever negation syntax the framework supports; otherwise restructure as ordered fallback)
  - add: new conditional line after the bullets: `` `Fetch the issue at ${issue_url} and save it to ${change_folder}/issue.md following @artdef_issue_file. (?fetchable_maybe)` ``; the `@artdef_issue_file` reference pulls the new artdef into the rendered AGENT_INSTRUCTIONS only when the conditional fires (the framework's dep scan runs on the post-filter body)

- [x] create: [prompts/artdef_change_context.md](../../../../../bin/prompts/artdef_change_context.md)
  - New artifact definition mirroring `artdef_change_why_what.md` shape but emitting a single `## Context` section
  - Body template: `[2-3 sentences distilling the issue]` followed by `See [issue.md](issue.md) for the originating ticket.`
  - Used by `instr_uchange.md` when `--fetchable` is passed

- [x] create: [prompts/artdef_issue_file.md](../../../../../bin/prompts/artdef_issue_file.md)
  - New artifact definition prescribing the `issue.md` shape: H1 with the issue title, metadata as a bullet list immediately after (URL, ID, State, Author, Labels, Fetched at; optional Assignees/Milestone/Closed at/Linked PRs when available), then the issue body verbatim
  - Wrap rule: if the body does not start with a markdown heading, the agent prepends `## Description`; a leading H1 in the source body is demoted to H2
  - Referenced by `instr_uchange.md` via `@artdef_issue_file` in the conditional fetch line, so it is pulled in only when `--fetchable` is passed

- [x] update: [templates/actions/uchange.yaml](../../../../../scripts/templates/actions/uchange.yaml)
  - add to the `raw_text` instructions: when `{description}` references an issue URL, decide whether the AI Agent can fetch the issue (using its own skills, MCP integrations, and project rules in `AGENTS.md`/`CLAUDE.md`); if yes, also add `--fetchable`
  - update: `options` string to include `--fetchable`

## Quick start

The `--fetchable` flag is a new binary CLI option on `uchange` that the AI Agent passes when it can fetch the referenced issue:

- `uchange --issue-url <url> --fetchable ...` (issue is reachable) -- change.md uses the `## Context` shape and the agent is instructed to save the issue body to `issue.md`
- `uchange --issue-url <url> ...` (issue not reachable, or no fetch desired) -- change.md uses the existing `## Why` + `## What` shape; no fetch instruction is emitted
- `uchange --fetchable ...` without `--issue-url` -- error: `--fetchable requires an issue reference`

`issue_url` is recorded in frontmatter whenever provided, regardless of `--fetchable`, so `upr` continues to emit `[<issue_id>]` and `Closes #<issue_id>`.
