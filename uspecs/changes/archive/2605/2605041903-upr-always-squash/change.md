---
registered_at: 2026-05-04T18:50:17Z
change_id: 2605041850-upr-always-squash
baseline: 08ad48d5a242ad7a8187ec56e9ac2479f8ba0774
archived_at: 2026-05-04T19:03:42Z
---

# Change request: Always squash and force-push in upr

## Why

The upr action currently branches on commit count: single-commit branches are pushed as-is, multi-commit branches are squashed and force-pushed. This dual flow complicates the code and prompts, and leaves single-commit branches with their original commit message instead of the standardized message derived from change.md. Unifying the flow yields consistent PR commits and removes a code path.

## What

Unify upr to always squash the branch into a single commit and force-push, regardless of commit count.

- Always squash to one commit using the standardized commit_message and force-push with `--force-with-lease`
- Always emit the success prompt that includes the pre-push HEAD restore hint
- Drop the "no squash" success prompt variant
- Align upr functional specification with the unified flow

## Functional design

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: collapse "No PR for current branch: single commit" and "No PR for current branch: multiple commits" scenarios into a single scenario where the branch is always squashed into one commit with commit_message and force-pushed, and Engineer is provided with restore instructions
  - update: "PR exists for current branch" Examples row for `CLOSED` state -> remove the qualifier "squash only if more than one commit" so new PR creation proceeds normally (always squash)
  - update: "PR title and commit message" scenario outline -> drop the "when squashing (multiple commits)" qualifier from the commit-message step; commit message is always applied
  - update: outcome references in "WCF is active" and "branch has no upstream" scenarios so they reference the unified scenario

## Construction

- [x] update: [tests/sys/softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - update: `_assert_no_pr_base_outcome` helper -> drop the `mode` parameter and the `nosquash` branch; always assert `upr_success` prompt is emitted, `upr_success_no_squash` is not, and the `git reset --keep` restore hint appears
  - update: call sites currently passing `"nosquash"` (`--no-archive keeps WCF active`, `WCF already archived`) -> remove the argument so they assert the unified squash outcome

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: `cmd_action_upr` -> remove the `if [[ "$commit_count" -gt 1 ]]` / `else` branch; always record `pre_push_head`, soft-reset to `merge_base`, recommit with `commit_message`, register the atexit restoration handler, and `git push --force-with-lease`
  - update: success-prompt selection -> always emit `instr_upr_success` with `pre_push_head` and `pr_url`; drop the `instr_upr_success_no_squash` branch
  - keep: the `commit_count` log line for diagnostics

- [x] remove: `[bin/prompts/instr_upr_success_no_squash.md](../../../../../bin/prompts/instr_upr_success_no_squash.md)`
  - no longer referenced after the success-prompt selection is unified
