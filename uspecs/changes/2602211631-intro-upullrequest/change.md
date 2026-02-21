---
registered_at: 2026-02-21T16:31:04Z
change_id: 2602211631-intro-upullrequest
baseline: 97c4e5cb605baeec49bddcafdbcb0e6553d23f59
---

# Change request: Introduce upr command

## Why

Creating a pull request from a change branch requires multiple manual git steps. A dedicated `upr` command automates the full workflow: squashing the work branch, opening a PR, and removing the source branch.

## What

- New `upr.feature` scenarios file in `specs/prod/softeng/`
- New `actn-upr.md` action file for the AI agent
- New commands in `uspecs.sh`: `pr` (subcommands: `mergedef`, `create`) and `diff specs` (agent always calls `uspecs.sh`, never `_lib/pr.sh` directly)
- New commands in `_lib/pr.sh`: `mergedef`, `diff`, `changepr`; `diff` takes a target argument (e.g., `specs`); extract shared PR creation logic (repo detection, `upstream` vs `origin` handling, `gh pr create`) into a helper to avoid duplication with `cmd_pr`
- `conf.md` updated with PR branch naming convention
- `AGENTS.md` updated with `upr` trigger entry

## How: create a PR from a change branch

Concepts:

- pr_remote: the remote that owns the PR target branch; `upstream` when a fork is detected, otherwise `origin`
- change_branch: the current branch; named `{change-name}`
- pr_branch: the branch used for the PR, named `{change-name}--pr`
- issue_url, issue_id: read from `change.md` frontmatter `issue_url` field; may be absent

Validation:

- git repository present
- working tree is clean
- current branch is not the default branch and does not end with `--pr`; it becomes `change_branch`
- `mergedef --validate` outputs `change_branch=...` and `default_branch=...` without fetching or merging

Flow overview:

- Validate preconditions via `uspecs.sh pr mergedef --validate`; parse `change_branch` and `default_branch` from output; stop on error
- Ask confirmation to create a PR from `change_branch`; notify that branch will be squash-merged into a new branch and deleted after PR creation
- Fetch `pr_remote` and merge `pr_remote/default_branch` into `change_branch`
  - Surfaces conflicts in the familiar `change_branch` context rather than during the squash step; merge preferred over rebase because conflict resolution is single-pass and history rewriting does not matter since the branch is deleted after squash
  - `uspecs.sh pr mergedef`, uses `_lib/pr.sh mergedef`
  - If merge fails, script exits with error; agent asks user to resolve conflicts and re-run
- Define `pr_title` and `pr_body`:
  - `uspecs.sh diff specs` gets a diff between `{specs_folder}` at the current commit and the tip of `pr_remote/default_branch`
    - Uses `_lib/pr.sh diff` with `specs` argument
  - Agent:
    - Identifies `draft_title` and `draft_body` from the diff
    - Constructs `pr_title` and `pr_body` using a PR template:
      - If `issue_url` is present: pr_title `[{issue_id}] {draft_title}`, pr_body `[{issue_id}]({issue_url}) {draft_title}\n\n{draft_body}`
      - If `issue_url` is absent: pr_title `{draft_title}`, pr_body `{draft_title}\n\n{draft_body}`
- Create PR
  - `uspecs.sh pr create --title {pr_title} --body {pr_body}`, uses `_lib/pr.sh changepr`
    - Fail fast if `pr_branch` already exists
    - Create `pr_branch` from `pr_remote/default_branch` (reuse `cmd_prbranch`)
    - Squash-merge `change_branch` into `pr_branch`, commit with `pr_title`
    - Push `pr_branch` to `origin` (in fork setups this is the fork remote; `gh pr create` targets `upstream` automatically)
    - Create a PR to `pr_remote/default_branch` via GitHub CLI using `pr_title` and `pr_body`
    - Output `pr_url` to the caller
    - Delete `change_branch` locally, its remote tracking ref, and the remote branch; skip silently if absent, warn if deletion fails for another reason
    - Engineer stays on `pr_branch` to address review comments
  - Agent reports that PR is created and shows `pr_url` to Engineer

Error handling in `_lib/pr.sh`:

- On failure after `pr_branch` creation: delete `pr_branch` locally, its remote tracking ref, and the remote branch; preserve `change_branch`
