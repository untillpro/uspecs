---
registered_at: 2026-03-12T07:00:31Z
change_id: 2603120700-introduce-uaccept
baseline: c9614d33d1f10184c96e64781e1fe3b439938e6f
---

# Change request: Introduce uaccept action

## Why

After a PR is reviewed and approved, finalizing it requires several manual steps: archiving all active changes, merging the PR with squash, and cleaning up local branches. Automating this via a dedicated `uaccept` action ensures the process is always executed consistently and reduces friction for the Engineer.

## What

Requirements:

### upr

- Prechecks
  - Clean working tree (must be cleaned)
  - Current branch is not default branch
  - There is only one Active Change Folder with changes (vs pr-target/branch)
- pr_title: If url exists then pr title is taken from change.md name
- if more than one commit then new branch --pr is created and will be used as pr_branch, otherwise the current branch is used as pr_branch


## Misc

Introduce a new `uaccept` action and supporting script command:

New action file `uspecs/u/actn-uaccept.md`:

- Engineer invokes `uaccept` when a PR is ready to accept
- Agent runs `bash uspecs/u/scripts/uspecs.sh pr accept`
- Agent reports the result

local_delete

- command in pr.sh  that in uspecs_Deletes local PR branch and remote tracking ref

New `pr accept` subcommand in `uspecs/u/scripts/uspecs.sh`:

- Reads `change.md` frontmatter; fails with a clear message if `pr_number:` field is absent
- Checks PR mergeability via `gh pr view <pr_number> --json mergeable,mergeStateStatus`; fails with a clear message if not mergeable
- Runs `uspecs change archiveall` to stage archive operations
- If there are staged changes, commits and pushes them (so archive commits are included in the PR)
- Attempts `gh pr merge --squash --delete-branch --auto <pr_url>`; does not fail on error, only warns
- Checks out the default branch
- Deletes local PR branch and remote tracking ref

frontmatter management functions

- functions in utils.sh to read/write frontmatter
- reuse these functions from existing code

Update `upr` action and `pr create` script to write `pr: <pr_url>` into `change.md` frontmatter after the PR is created; this field is the prerequisite that `uaccept` checks.

Update `uspecs/u/actn-upr.md` to document that `pr:` is written to frontmatter.

Update `AGENTS.md` / `CLAUDE.md` keyword table to register the `uaccept` keyword.
