---
registered_at: 2026-04-01T15:56:25Z
change_id: 2604011556-upr-create-and-umergepr-url
baseline: 490e6915196ce61928db653c42eb3c172681b2a0
archived_at: 2026-04-01T16:11:00Z
---
# Change request: upr should create PR and umergepr should show PR URL

## Why

Currently `upr` only opens the browser for manual PR creation instead of creating the PR programmatically. Also `umergepr` does not show the PR URL in its success output, making it harder to reference the merged PR.

## What

Two improvements to the PR workflow scripts:

- `upr` (`cmd_action_upr` in `softeng.sh`): replace `gh pr create --web` with `gh_create_pr` to actually create the PR, capture the returned `pr_url`, then open the PR in browser via `gh pr view --web`
- `umergepr` (`cmd_action_umergepr` in `softeng.sh`): add `pr_url` to the `success_vars` map so the prompt template can display it
- Update `prompts.md` templates:
  - `upr_success` / `upr_success_no_squash`: update text to reflect PR is created (not just "page opened"), include `${pr_url}`
  - `umergepr_success`: include `${pr_url}` in the success message
