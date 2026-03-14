---
registered_at: 2026-03-12T07:00:31Z
change_id: 2603120700-introduce-uaccept
baseline: c9614d33d1f10184c96e64781e1fe3b439938e6f
---

# Change request: Introduce uaccept action

## Why

After a PR is reviewed and approved, finalizing it requires several manual steps: archiving all active changes, merging the PR with squash, and cleaning up local branches. Automating this via a dedicated `uaccept` action ensures the process is always executed consistently and reduces friction for the Engineer.

## Background

- https://claude.ai/chat/3b6882d3-33dc-4e17-8146-7cee7769ad91

## What

### utils

- prompt_block file, block_id
  - Dumps the content of the specified block to stdout

### upr

Prerequisites:

- Clean working tree (must be cleaned)
- Current branch is not default branch
- There is only one Active Change Folder with changes (vs pr_remote/default_branch)
  - pr_change_folder
  - Message: "Expected exactly one modified Active Change Folder, found {n}" followed by a list of the relative (project root) paths of the modified Active Change Folders

Data:

- pr_title: Taken from the change.md title
- pr_body: Prepared by Agent from pr_change_folder

Flow:

- Agent runs uspecs.sh pr precheks
- uspecs.sh
  - calls pr.sh changepr prechecks
    - Perform the prechecks; if any check fails, exits with a non-zero code and a clear error message
    - Return prompt to construct `draft_body` and rerun `uspecs.sh pr create --body "{draft_pr_body}"`
      - Taken from prompts.md `## pr_precheks: Construct draft_body and return uspecs.sh with pr create command`
        - utils `prompt_block(prompts.md, pr_precheks)`
- Agent constructs `draft_body` and runs `uspecs.sh pr create`
- uspecs.sh
  - calls pr.sh changepr create
    - Determine pr_change_folder
    - Determine draft_title from pr_change_folder
    - If branch has more than one commit ahead of pr_remote/default_branch
      - git reset --soft pr_remote/default_branch
    - commit with
- pr.sh mergedef -> pr.sh changepr prechecks
  - No merge


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
