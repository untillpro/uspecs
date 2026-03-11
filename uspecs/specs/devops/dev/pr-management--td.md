# Feature technical design: pr-management

## Key components

Feature components:

- [pr-uaccept.yml: GitHub Action](../../../../.github/workflows/pr-uaccept.yml)
  - Triggered by `issue_comment` event (type: created) on pull requests
  - Guards: comment body is exactly "uaccept", commenter association is OWNER, MEMBER, or COLLABORATOR
  - Permissions: `contents: write`, `pull-requests: write`
  - Passes `PR_NUMBER`, `COMMENT_ID`, `GH_TOKEN` to the script

- [pr-uaccept.sh: bash script](../../../../scripts/pr-uaccept.sh)
  - Reacts to the "uaccept" comment with +1
  - Runs `uspecs change archiveall` to archive all active change requests
  - Merges the PR with squash and auto-merge via `gh pr merge --squash --auto --delete-branch`
  - Posts a summary comment instructing Developer to run `uarchive` locally

## Key flows

### Developer posts "uaccept" comment

```text
Developer posts comment "uaccept" on PR
  |
  v
GitHub: issue_comment event -> pr-uaccept.yml
  |
  +-- not a PR comment           --> ignore
  |
  +-- comment != "uaccept"       --> ignore
  |
  +-- commenter not Write role   --> ignore
  |
  v
pr-uaccept.sh
  |
  +-- react to comment with +1
  |
  +-- uspecs change archiveall
  |
  +-- gh pr merge --squash --auto --delete-branch
  |
  +-- post summary comment (run uarchive locally)
  |
  v
PR merged, remote branch deleted
```
