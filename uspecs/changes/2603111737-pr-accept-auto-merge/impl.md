# Implementation plan: PR accept comment triggers archiveall and squash merge

## Functional design

- [x] create: [dev/pr-management.feature](../../specs/devops/dev/pr-management.feature)
  - add: Scenario "PR accept comment" - Developer with Write access posts "uaccept", system reacts, archives, merges with squash, deletes remote branch, notifies to run uarchive

## Technical design

- [x] create: [dev/pr-management--td.md](../../specs/devops/dev/pr-management--td.md)
  - add: Key components (pr-uaccept.yml workflow, pr-uaccept.sh script with env vars)
  - add: Key flows - vertical ASCII sequence diagram with role validation guards

## Construction

- [x] create: [scripts/pr-uaccept.sh](../../../scripts/pr-uaccept.sh)
  - add: react to "uaccept" comment with +1 via `gh api`
  - add: run `uspecs change archiveall`
  - add: commit and push staged archived changes (if any) before merge
  - add: merge PR with `gh pr merge --squash --auto --delete-branch`
  - add: post summary comment instructing Developer to run `uarchive`

- [x] create: [.github/workflows/pr-uaccept.yml](../../../.github/workflows/pr-uaccept.yml)
  - add: trigger on `issue_comment` event (type: created) for pull requests
  - add: guard: comment body exactly "uaccept", commenter is OWNER/MEMBER/COLLABORATOR
  - add: permissions `contents: write` and `pull-requests: write`
  - add: step to checkout PR branch via `gh pr checkout` (issue_comment defaults to default branch)
  - add: pass `PR_NUMBER`, `COMMENT_ID`, `GH_TOKEN` to pr-uaccept.sh

- [x] update: [uspecs/u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)
  - add: `cmd_change_archive -d` early-exit when remote branch is gone: skip archive, refresh default branch, clean up local PR branch

- [x] update: [tests/sys/uspecs.sh-change-archive.bats](../../../tests/sys/uspecs.sh-change-archive.bats)
  - update: "remote branch gone" test to verify archive is skipped (not just push)
