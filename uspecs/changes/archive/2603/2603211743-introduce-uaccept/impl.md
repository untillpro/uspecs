# Implementation plan: Introduce uaccept action

## Functional design

- [x] update: [prod/domain.md](../../../../specs/prod/domain.md)
  - add: Working Change Folder concept under uspecs concepts

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: Scenario "Create pull request" to reflect Working Change Folder prerequisite, archiving, upstream setting, squash commit flow
  - update: PR title/body scenario to use new definitions (change_title, pr_title, commit_message)
  - update: Edge cases to include Working Change Folder validation and PR-already-exists case
  - add: Prompt with next steps after successful PR creation

- [x] create: [softeng/uaccept.feature](../../../../specs/prod/softeng/uaccept.feature)
  - add: Scenario for accepting PR when in OPEN state (archive, squash merge, branch cleanup)
  - add: Scenario for PR not found
  - add: Scenario for PR not in OPEN state (open in browser, delete local branch)
  - add: Edge case for merge failure (open in browser, prompt to retry)
  - add: Working Change Folder prerequisite validation

## Construction

### Prompt templates

- [x] update: [u/scripts/prompts.md](../../../../u/scripts/prompts.md)
  - add: `upr_already_exists` section - PR already exists, opened in browser
  - add: `uaccept_success` section - merge succeeded, report to Engineer
  - add: `uaccept_no_pr` section - no open PR found for current branch
  - add: `uaccept_not_open` section - PR not in OPEN state, browser opened, branch deleted, how to restore
  - add: `uaccept_merge_failed` section - merge failed, browser opened, handle manually, run uaccept again

### Shared helpers

- [x] update: [u/scripts/_lib/utils.sh](../../../../u/scripts/_lib/utils.sh)
  - add: `md_read_frontmatter_field` - extract named field from YAML frontmatter
  - add: `md_read_title` - extract first `#` heading text from a markdown file
- [x] create: [tests/unit/utils-md.bats](../../../../../tests/unit/utils-md.bats)
  - add: unit tests for `md_read_frontmatter_field` - field present, field absent, no frontmatter, multi-line frontmatter, missing file
  - add: unit tests for `md_read_title` - standard title, title with colon prefix, no heading, missing file  
- [x] Review

### Script implementation

- [x] update: [u/scripts/uspecs.sh](../../../../u/scripts/uspecs.sh)
  - add: `prompt` top-level command dispatch (upr, uaccept)
  - add: `changes_detect_wcf` helper - Working Change Folder detection via git diff against merge-base, validates exactly one found
  - add: `cmd_prompt_upr` - full upr flow: validate preconditions, detect WCF, check no existing PR, read change.md, compute pr_title/commit_message/see_details_line, archive WCF if active, set upstream, squash branch, force-push, open PR creation in browser via `gh pr create --web`, output upr_success prompt
  - add: `cmd_prompt_uaccept` - full uaccept flow: validate preconditions, detect WCF, check PR state via `gh pr view`, handle not-found/OPEN/not-OPEN branches, archive WCF if active, attempt merge via `gh pr merge -s -d`, handle merge failure, branch cleanup, output appropriate prompt section

### Tests

- [x] create: [tests/sys/uspecs.sh-prompt-upr.bats](../../../../../tests/sys/uspecs.sh-prompt-upr.bats)
  - PR already exists - opens browser, displays message
  - Successful creation flow - archive WCF, squash, force-push, open PR creation in browser, output next steps
  - pr_title and commit_message with issue_url
  - pr_title and commit_message without issue_url
  - Edge: no changes since branching from default branch
  - Edge: no git repository
  - Edge: working tree has uncommitted changes
  - Edge: current branch is the default branch
  - Edge: not exactly one Working Change Folder exists
  - Edge: change folder has uncompleted todo items
- [x] Review
