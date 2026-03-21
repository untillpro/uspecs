# Prompts

## upr_already_exists: PR already exists for current branch

Inform Engineer that PR already exists for the current branch. It has been opened in your browser.

## upr_success: Next steps after PR creation

The PR creation page has been opened in your browser.

Next steps:

- Complete the PR creation form in the browser (review title and body, then submit)
- Fix any issues raised during review
- Run `uaccept` once the PR is approved and ready to merge

To restore your branch to its state before upr (undo the squash and force-push):

```text
git reset --hard ${pre_push_head}
git push --force
```

## uaccept_success: PR merged successfully

PR #${pr_number} has been merged successfully.

Local branch `${branch_name}` and its remote tracking ref have been deleted.

## uaccept_no_pr: No open PR for current branch

No open PR found for the current branch.

## uaccept_not_open: PR is not in OPEN state

PR #${pr_number} is in ${pr_state} state (not OPEN). It has been opened in your browser.

Local branch `${branch_name}`, upstream, and remote tracking ref have been deleted (errors ignored).

To restore the local branch:

```text
git branch ${branch_name} ${branch_head}
```

## uaccept_merge_failed: Merge attempt failed

Merge of PR #${pr_number} failed. The PR has been opened in your browser.

Handle the PR manually (resolve conflicts, adjust settings, etc.) and run `uaccept` again.

## upr_uncompleted_todos: Change folder has uncompleted todo items

Cannot create PR: ${uncompleted_count} uncompleted todo item(s) found in files:

${uncompleted_files}

Complete todo items before creating a PR.
