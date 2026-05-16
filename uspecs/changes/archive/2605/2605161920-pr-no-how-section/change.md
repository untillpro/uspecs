---
registered_at: 2026-05-16T19:08:16Z
change_id: 2605161908-pr-no-how-section
type: fix
scope: softeng
baseline: 5b55527a1259cbf81e9d0f3d8fca388337ad9487
issue_url: https://github.com/untillpro/uspecs/pull/84
archived_at: 2026-05-16T19:20:00Z
---

# Change request: Exclude How section from PR body

## Why

The `## How` section of `change.md` captures internal implementation decisions, scope boundaries, and supporting references. That content is valuable inside the Change Folder but is noise in a PR description and consumes the limited 40-line / 4000-character PR body budget. PRs such as [uspecs#84](https://github.com/untillpro/uspecs/pull/84) render `## How` with little or no visible content because the budget is exhausted on its decisions list before the more important Why/What narrative reaches the reader. Dropping How from the PR body keeps the description focused on rationale and scope.

## What

Restrict the `upr` PR body composition to the frontmatter, `## Why`, and `## What` sections only; `## How` is no longer copied into the PR body.

- `upr` PR body content -- frontmatter (YAML-fenced) + Why + What
- `upr` Functional Design specification -- updated wording for the composed body
- `upr` system tests -- updated assertions and helper

The How section continues to be authored in `change.md` (still produced by `uchange`); only its inclusion in the PR body is dropped.

## How

Decisions:

- Narrow the section filter in `cmd_action_upr` (`bin/softeng.sh`) by changing the awk regex from `^## (Why|What|How)[[:space:]]*$` to `^## (Why|What)[[:space:]]*$`; rename the internal awk variable from `in_why_what_how` to `in_why_what` and update the surrounding comment
- Update the scenario step in [`upr.feature`](../../../../specs/prod/softeng/upr.feature) so the composed body lists only the Why and What sections
- Update [`softeng.sh-action-upr.bats`](../../../../../tests/sys/softeng.sh-action-upr.bats):
  - drop the `[[ "$gh_body" == *"## How"*"How narrative."* ]]` assertion in the subject test
  - add an assertion that `## How` / `How narrative.` does NOT appear in the PR body
  - update the `_assert_pr_body_format` helper comment ("non-Why/What sections filtered out")
- Keep `_make_upr_change` emitting a `## How` section so the filter is exercised by the new "must not appear" assertion

Out of scope:

- Removing the `## How` section from `change.md` itself or from the `uchange` flow
- Changing PR body truncation limits or frontmatter handling
- Adjusting which sections are included in any other artifact (commit message, comments, etc.)

References:

- [PR body awk filter in cmd_action_upr](../../../../../bin/softeng.sh)
- [upr functional design](../../../../specs/prod/softeng/upr.feature)
- [upr system tests](../../../../../tests/sys/softeng.sh-action-upr.bats)
- [PR #84 illustrating the empty How section](https://github.com/untillpro/uspecs/pull/84)

## Functional design

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: "No PR for current branch: PR title and commit message" scenario -- in the step describing `pr_body` composition, drop "and How" so the list reads "followed by the Why and What sections"

## Construction

### Tests

- [x] update: [sys/softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - update: `_assert_pr_body_format` header comment from "non-Why/What/How sections filtered out" to "non-Why/What sections filtered out"
  - update: "action upr: subject: type only, no scope, no breaking" test (around the `_assert_subject_and_trailers "feat: Add feature"` block) -- replace the `[[ "$gh_body" == *"## How"*"How narrative."* ]]` assertion with `[[ "$gh_body" != *"## How"* ]] && [[ "$gh_body" != *"How narrative."* ]]`
  - update: PR-body comment "PR body still carries the Why/What/How sections from change.md" -> "PR body still carries the Why/What sections from change.md (How is filtered out)"
  - keep: `_make_upr_change` emitting a `## How` section so the new "must not appear" assertion exercises the filter

### Implementation

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: PR-body `awk` in `cmd_action_upr` -- change the section-match regex from `^## (Why|What|How)[[:space:]]*$` to `^## (Why|What)[[:space:]]*$` and rename the awk variable `in_why_what_how` to `in_why_what`
  - update: surrounding comment "emit only the Why, What and How sections from change.md" -> "emit only the Why and What sections from change.md"
