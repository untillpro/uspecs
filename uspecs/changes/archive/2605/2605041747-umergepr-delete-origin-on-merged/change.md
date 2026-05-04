---
registered_at: 2026-05-04T17:23:53Z
change_id: 2605041723-umergepr-delete-origin-on-merged
baseline: 41149330507df0fb64c45ac6af22344f413bafca
issue_url: https://github.com/untillpro/uspecs/pull/74
archived_at: 2026-05-04T17:47:20Z
---

# Change request: umergepr handles MERGED and non-MERGED PRs differently

## Why

When a PR is merged manually via the GitHub UI before the Engineer runs `umergepr`, the action observes a non-OPEN PR state and force-deletes local refs but leaves the remote branch on `origin` (the fork) alive, leaving stale branches such as the one in https://github.com/untillpro/uspecs/pull/74. At the same time, treating all non-OPEN states identically is unsafe: a CLOSED-without-merge PR may carry work the Engineer still needs, and force-deleting the local branch destroys their easiest recovery path.

## What

Split the not-OPEN behavior of `umergepr` into two distinct cases:

- PR in MERGED state: full cleanup - open PR in browser, delete local branch and tracking ref, delete the branch on `origin`, inform the Engineer
- PR in any other non-OPEN state (e.g. CLOSED): show the PR in browser and inform the Engineer; do not delete the local branch, the upstream tracking ref, or the branch on `origin`

Behavior matrix:

| PR state            | Open in browser | Delete local branch + tracking ref | Delete origin branch | Inform Engineer |
|---------------------|-----------------|------------------------------------|----------------------|-----------------|
| OPEN (merge ok)     | no              | yes (via `gh pr merge -d`)         | yes                  | yes             |
| MERGED              | yes             | yes                                | yes (new)            | yes             |
| non-MERGED (CLOSED) | yes             | no (changed)                       | no                   | yes             |

Deliverables:

- Behavior change in the `umergepr` action for the not-OPEN path
- Updated Functional Design for `umergepr` covering the MERGED vs non-MERGED distinction
- Updated user-facing prompts reflecting the two outcomes
- Updated and added system tests covering MERGED and CLOSED variants

Out of scope:

- Behavior of the OPEN-success path (already deletes origin branch)
- Any changes to `upr` or other actions
- Interactive prompts to confirm cleanup

## Functional design

- [x] update: [softeng/umergepr.feature](../../../../specs/prod/softeng/umergepr.feature)
  - apply the behavior matrix to the scenarios covering non-OPEN PRs, splitting them into MERGED and non-MERGED paths

## Construction

### Tests

- [x] update: [tests/sys/softeng.sh-action-umergepr.bats](../../../../../tests/sys/softeng.sh-action-umergepr.bats)
  - rename existing test "PR not in OPEN state" to "PR in MERGED state"
  - add: assertion that origin branch `my-feature` is deleted (`git ls-remote --heads origin my-feature` is empty)
  - add: new test "PR in non-MERGED, non-OPEN state" using `state=CLOSED`, asserting local branch, upstream tracking ref and origin branch are all preserved, and the prompt reflects no deletion

### Prompts

- [x] rename: [bin/prompts/instr_umergepr_merged.md](../../../../../bin/prompts/instr_umergepr_merged.md) (was `instr_umergepr_not_open.md`)
  - update: text to describe MERGED outcome including origin branch deletion
- [x] create: [bin/prompts/instr_umergepr_not_merged.md](../../../../../bin/prompts/instr_umergepr_not_merged.md)
  - Purpose: informs the Engineer that PR is in a non-MERGED, non-OPEN state and was opened in the browser
  - Content: state, pr_number, no deletions performed, no recovery instructions needed

### Source

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: `cmd_action_umergepr` not-OPEN branch -> dispatch on `pr_state`:
    - `MERGED`: open PR in browser, delete local branch and upstream tracking ref, delete origin branch via `git push origin --delete` if it exists, emit `instr_umergepr_merged`
    - other states: open PR in browser, perform no deletions, emit `instr_umergepr_not_merged`
