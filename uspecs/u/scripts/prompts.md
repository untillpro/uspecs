# Prompts

## upr_already_exists: instructions: PR already exists for current branch

PR already exists for the current branch: ${pr_url}

It has been opened in the browser.

## upr_already_merged: info: PR was already merged

PR #${pr_number} for this branch was already merged. Proceeding with new PR creation...

## upr_success: instructions: Next steps after PR creation

The PR creation page has been opened in your browser.

To restore branch to its pre-squash state, if needed:

```text
git reset --hard ${pre_push_head}
git push --force
```

Next steps:

- Complete the PR creation form in the browser (review title and body, then submit)
- Fix any issues raised during review
- Run `uaccept` once the PR is approved and ready to merge

## uaccept_success: instructions: PR merged successfully

PR #${pr_number} has been merged successfully.

Local branch `${branch_name}` and its remote tracking ref have been deleted.

To restore the local branch, if needed:

```text
git branch ${branch_name} ${branch_head}
```

## uaccept_no_pr: instructions: No open PR for current branch

No open PR found for the current branch.

## uaccept_not_open: instructions: PR is not in OPEN state

PR #${pr_number} is in ${pr_state} state (not OPEN). It has been opened in your browser.

Local branch `${branch_name}`, upstream, and remote tracking ref have been deleted (errors ignored).

To restore the local branch:

```text
git branch ${branch_name} ${branch_head}
```

## uaccept_merge_failed: instructions: Merge attempt failed

Merge of PR #${pr_number} failed. The PR has been opened in your browser.

Handle the PR manually (resolve conflicts, adjust settings, etc.) and run `uaccept` again.
