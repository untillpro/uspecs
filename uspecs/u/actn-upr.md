# Action: Create pull request

## Overview

Create a pull request from the current change branch by squash-merging it into a dedicated PR branch and submitting via GitHub CLI.

## Instructions

Rules:

- Strictly follow the definitions from `uspecs/u/concepts.md` and `uspecs/u/conf.md`
- Always call `uspecs.sh` for git/PR operations — never call `_lib/pr.sh` directly
- Read `change.md` frontmatter to determine `issue_url` and `issue_id`

Parameters:

- Input
  - Active Change Folder (change.md for issue_url)
  - change_branch: current git branch
- Output
  - PR created on GitHub
  - pr_branch: `{change_branch}--pr` with squashed commits
  - change_branch deleted

Flow:

- Read Active Change Folder (change.md) to determine `issue_url` (may be absent) and derive `issue_id` from the URL (last path segment)
- Ask Engineer to confirm PR creation from `change_branch`; inform that the branch will be squash-merged into `{change_branch}--pr` and deleted after PR creation
- Validate preconditions and merge default branch into change_branch:
  - Run `bash uspecs/u/scripts/uspecs.sh pr mergedef`
  - If script exits with error (validation failure): report the error and stop
  - If merge fails (conflicts): report error and ask Engineer to resolve conflicts and re-run
- Get specs diff to derive PR title and body:
  - Run `bash uspecs/u/scripts/uspecs.sh diff specs`
  - From the diff output identify `draft_title` and `draft_body`; construct `pr_title` and `pr_body` per `{templates_folder}/tmpl-pr.md`
- Create PR:
  - Run `bash uspecs/u/scripts/uspecs.sh pr create --title "{pr_title}" --body "{pr_body}"`
  - If script exits with error: report the error and stop
  - Parse `pr_url` from script output
- Report `pr_url` to Engineer; inform that Engineer is now on `pr_branch` to address review comments
