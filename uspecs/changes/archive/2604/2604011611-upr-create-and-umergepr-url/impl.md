# Implementation plan: upr should create PR and umergepr should show PR URL

## Functional design

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: "PR creation is opened in the browser" -> PR is created programmatically via gh CLI, then opened in the browser
  - update: pr_body truncation note removed (no longer needed without --web URL length limits)
  - update: next steps prompt reflects PR is already created (no "complete the form" step)

- [x] update: [softeng/umergepr.feature](../../../../specs/prod/softeng/umergepr.feature)
  - add: pr_url is displayed in the success message after merge

## Construction

- [x] update: [softeng.sh](../../../../u/scripts/softeng.sh)
  - update: `cmd_action_upr` (~line 993-997) - replace `gh pr create --web` with `gh_create_pr` (pipe from body file), capture `pr_url`, then open browser with `quiet gh pr view --web`
  - update: `cmd_action_upr` (~line 962) - remove comment about URL-length limits
  - update: `cmd_action_upr` (~line 999-1007) - pass `pr_url` into success prompt vars
  - update: `cmd_action_umergepr` (~line 1063) - capture `pr_url` via `gh pr view --json url -q ".url"` (before merge deletes the PR branch)
  - update: `cmd_action_umergepr` (~line 1184) - add `[pr_url]="$pr_url"` to `success_vars`

- [x] update: [prompts.md](../../../../u/prompts.md)
  - update: `upr_success` - "PR creation page has been opened" -> "PR has been created: ${pr_url}", remove "Complete the PR creation form" step
  - update: `upr_success_no_squash` - same changes as upr_success
  - update: `umergepr_success` - add `${pr_url}` line to success message

- [x] update: [softeng.sh-prompt-upr.bats](../../../../../tests/sys/softeng.sh-prompt-upr.bats)
  - update: `_assert_no_pr_base_outcome` - change `pr create --web` assertion to `pr create` (without `--web`), add `pr view --web` assertion
  - update: add `pr_url` assertion to success output checks

- [x] update: [softeng.sh-prompt-umergepr.bats](../../../../../tests/sys/softeng.sh-prompt-umergepr.bats)
  - update: add `pr_url` assertion to "PR in OPEN state" and "upstream remote exists" tests
