---
registered_at: 2026-05-20T14:12:43Z
change_id: 2605201412-uchange-fetchable-refs-shape
type: feat
scope: softeng
baseline: 606ac950d29c7e9153f65e3b6bbaae94638b30b7
archived_at: 2026-05-20T17:00:57Z
---

# Change request: Use Refs + Why/What/How shape for fetchable change.md

## Why

The current `--fetchable` variant collapses the originating issue into a single `## Context` section, which drops the standard Why/What/How reasoning structure that the non-fetchable variant and downstream tooling rely on. This asymmetry forces reviewers to open `issue.md` to recover intent and produces two divergent `change.md` formats for the same action.

## What

The `change.md` produced by `uchange` with a fetchable issue reference adopts a single shape that pairs issue links with the standard reasoning sections, replacing the `## Context`-only variant in the softeng (dev) context:

- The heading is followed by a `Refs:` block placed before any prose section, rendered as a markdown bulleted list with one entry per referenced issue using the link form `- [{issue-number}: {issue-title}](./issue-{issue-number}.md)`; the saved issue file is named `issue-{issue-number}.md` so its name is self-identifying and adding further issues later requires no renaming

- For now `uchange` accepts a single `--issue-url`, so the `Refs:` list always has exactly one entry; the CLI surface remains single-issue in this change

- The `{issue-number}` token used in the filename and link text is extracted by the agent from `--issue-url` per its prompt instructions (handling common issue-tracker URL shapes: GitHub, GitLab, Jira, etc.); the bash `extract_issue_id` helper is no longer the gate for `--fetchable` -- it remains in place for the existing `upr` `Closes #<id>` plumbing on GitHub URLs and is unaffected by this change

- Under `--fetchable`, the agent populates `## Why` and `## What` by distilling them from the fetched issue (in the change's terms, not by restatement -- the link in `Refs:` suffices); the semantics and per-type guidance for both sections, defined in `artdef_change_why_what.md`, are unchanged

- A `## How` section captures the key approach (components touched, sequence, or design choice) at a high level, deferring detail to the implementation plan. Emission rules under `--fetchable`: when `--how` is passed, `## How` is always emitted as today; when `--how` is omitted, the agent inspects the fetched issue and emits `## How` distilled from issue content only if the issue describes an approach/design/how, otherwise the section is omitted. Under non-fetchable shape `## How` emission follows the existing `--how` flag semantics unchanged

- The H1 heading prefix remains `# Change request: ...` in both fetchable and non-fetchable shapes (no rename); downstream consumers that match the heading are unaffected

- The `## Context` variant is no longer emitted by `uchange --fetchable`; the non-fetchable shape (no issue reference, no `--fetchable`) is unchanged

## Functional design

- [x] update: [softeng/uchange.feature](../../../../specs/prod/softeng/uchange.feature)
  - replace the `## Context` body_shape row in the `Issue reference provided` outline with the Refs + Why/What shape
  - add scenario `Refs block under --fetchable` covering the bulleted-list placement, link form, and agent-side `{issue-number}` extraction
  - add scenario `Why and What sourced from issue under --fetchable` covering distillation vs verbatim restatement and preserved per-type guidance
  - add scenario outline `## How section under --fetchable` covering the four `--how` x approach-in-issue combinations

- [x] update: [softeng/cross/issue-handling.feature](../../../../specs/prod/softeng/cross/issue-handling.feature)
  - update the `uchange.feature` cross-reference prose to describe the Refs + Why/What shape and the `issue-{issue-number}.md` filename
  - add cross-references for the three new uchange scenarios (Refs block, Why/What sourced from issue, ## How section)
  - annotate the `upr.feature` `Construct PR body` cross-reference as legacy `## Context` shape (archived `--fetchable` changes only)
  - update the `usync.feature` cross-reference to point at `issue-{issue-number}.md` instead of `issue.md`

- [x] update: [softeng/usync.feature](../../../../specs/prod/softeng/usync.feature)
  - update the `Core output` scenario to reference `issue-{issue-number}.md` in the Change Folder instead of the literal `issue.md`

## Construction

- [x] update: [softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - add: test `--fetchable with issue reference` covering Refs+Why/What artdefs, `artdef_change_refs` presence, `artdef_change_context` absence, `issue-{issue-number}.md` path pattern in fetch directive
  - add: test `--fetchable with --how` covering How artdef rendered alongside Refs+Why/What artdefs
  - add: test `--fetchable without --how (content-aware How)` covering `artdef_change_how` always present for fetchable and the content-aware emission rule ("emit only if" / "contains information for the How section") in dispatch instructions

- [x] update: [softeng.sh-action-usync.bats](../../../../../tests/sys/softeng.sh-action-usync.bats)
  - rename `Core output: issue.md triggers discrepancy reporting` to `Core output: issue-{issue-number}.md triggers discrepancy reporting`
  - seed the change folder with `issue-42.md` instead of `issue.md` and assert the discrepancy-reporting output mentions `issue-42.md`

- [x] update: [utils-emit-prompt.bats](../../../../../tests/unit/utils-emit-prompt.bats)
  - comment out the `prompt refs: all refs valid, no orphans` test pending the fix tracked in untillpro/uspecs#96 (dynamic `emit_prompt` id breaks the static orphan check; flags `instr_self_review_*` prompts as orphans)

- [x] create: [prompts/artdef_change_refs.md](../../../../../bin/prompts/artdef_change_refs.md)
  - Refs block artdef: heading `# Refs block`, `## data` section with the markdown template showing `Refs:` as a bulleted list with entry `[{issue-number}: {issue-title}](./issue-{issue-number}.md)`
  - Rules: extract `{issue-number}` from `--issue-url` via agent prompt instructions (not the bash `extract_issue_id` helper); one entry per issue

- [x] update: [prompts/artdef_change_why_what.md](../../../../../bin/prompts/artdef_change_why_what.md)
  - add Rules line `Insert the Refs: block from @artdef_change_refs between the H1 and ## Why (?fetchable_maybe)` so the artdef pulls `artdef_change_refs` in as a dependency under `--fetchable` and instructs the agent on placement
  - prepend `Basic example:` lede to the `## data` markdown template to distinguish the base shape from the conditional Refs insertion

- [x] update: [prompts/instr_uchange.md](../../../../../bin/prompts/instr_uchange.md)
  - drop the `@artdef_change_context (?fetchable_maybe)` dispatch line entirely (Refs handling delegated to `@artdef_change_why_what` via Rules + dep-walk)
  - change `@artdef_change_why_what` line to unconditional (single owner of the H1 in both shapes; pulls `@artdef_change_refs` in as a dep under `--fetchable`)
  - replace the single `@artdef_change_how (?how_maybe)` line with two mutually exclusive lines: one `(?how_maybe)` for always-emit, one `(?fetchable_no_how_maybe)` for content-aware emit -- phrase the content-aware line as "emit only if the fetched issue contains information for the How section; omit otherwise"
  - update the issue save path from `issue.md` to `issue-{issue-number}.md` and move the fetch directive to precede the change-file creation block so fetch happens before authoring

- [x] update: [prompts/instr_usync.md](../../../../../bin/prompts/instr_usync.md)
  - replace the literal `issue.md` reference in the discrepancy-reporting sentence with `${issue_file}` so the prompt reflects the agent-resolved `issue-{issue-number}.md` filename

- [x] update: [softeng.sh](../../../../../bin/softeng.sh)
  - add `fetchable_no_how_maybe` local variable (set when `opt_fetchable` is set and `opt_how` is not) after the existing `fetchable_maybe` assignment in `cmd_action_uchange`
  - add `[fetchable_no_how_maybe]="$fetchable_no_how_maybe"` to the `context_vars` array
  - in `cmd_action_usync`, replace the literal `issue.md` existence check with a glob over `issue-*.md`, set `issue_exists` and a new `issue_file` local (basename of the first match), and add `[issue_file]="$issue_file"` to both `usync_vars` arrays (large-diff and normal paths)
  - update the `convert_links_to_relative` comment example from `issue.md` to `issue-{issue-number}.md` to match the new filename convention

- [x] update: [actions/uchange.yaml](../../../../../scripts/templates/actions/uchange.yaml)
  - update the `--fetchable` description to say `change.md` uses the Refs + Why/What shape instead of the `## Context` shape; update the issue file name to `issue-{issue-number}.md`

- [x] delete: `[prompts/artdef_change_context.md](../../../../../bin/prompts/artdef_change_context.md)`
  - no longer referenced after `instr_uchange.md` switches to `artdef_change_refs`
