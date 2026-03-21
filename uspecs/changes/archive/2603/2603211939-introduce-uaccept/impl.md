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

### Agent configuration

- [x] update: [AGENTS.md](../../../../../AGENTS.md)
  - add: upr and uaccept to script-driven keywords (execute via `bash uspecs/u/scripts/uspecs.sh prompt {keyword}`)
  - remove: upr from file-driven keywords
- [x] update: [CLAUDE.md](../../../../../CLAUDE.md)
  - add: upr and uaccept to script-driven keywords (execute via `bash uspecs/u/scripts/uspecs.sh prompt {keyword}`)
  - remove: upr from file-driven keywords
- [x] update: [.gitignore](../../../../../.gitignore)
  - add: patterns for test output files (`*.out, *.out.*, *.tmp, *.tmp.*`)

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

### Test infrastructure

- [x] create: [tests/run-tests.py](../../../../../tests/run-tests.py)
  - add: parallel test runner for bats tests with pattern filtering
- [x] update: [tests/sys/stubs/gh](../../../../../tests/sys/stubs/gh)
  - add: pr view subcommand support (returns JSON or opens browser)
  - add: pr create subcommand support (accepts --body-file, returns PR URL)
  - add: pr merge subcommand support (can simulate failure via GH_STUB_MERGE_FAIL)

### Tests

- [x] create: [tests/sys/uspecs.sh-prompt-upr.bats](../../../../../tests/sys/uspecs.sh-prompt-upr.bats)
  - PR already exists in OPEN state - opens browser, displays message
  - PR already exists in CLOSED state - proceeds with new PR creation
  - PR already exists in MERGED state - notifies and proceeds with new PR creation
  - Successful creation flow - archive WCF, squash, force-push, open PR creation in browser, output next steps
  - Working Change Folder already archived - proceeds normally
  - pr_title and commit_message with issue_url
  - pr_title and commit_message without issue_url
  - Edge: no changes since branching from default branch
  - Edge: no git repository
  - Edge: working tree has uncommitted changes
  - Edge: current branch is the default branch
  - Edge: No Working Change Folder exists
  - Edge: Multiple Working Change Folders exist
  - Edge: change folder has uncompleted todo items
- [x] Review
- [x] create: [tests/sys/uspecs.sh-prompt-uaccept.bats](../../../../../tests/sys/uspecs.sh-prompt-uaccept.bats)
  - PR not found - displays message
  - PR in OPEN state - merge succeeds
  - PR in OPEN state - merge fails, opens browser, prompts to handle manually
  - PR in OPEN state - active WCF is archived before merge
  - PR is not in OPEN state - opens browser, deletes branch, informs about state
  - Edge: no git repository
  - Edge: working tree has uncommitted changes
  - Edge: current branch is the default branch
  - Edge: current branch has no upstream
  - Edge: No Working Change Folder exists
  - Edge: Multiple Working Change Folders exist
- [x] Review
- [x] update: [tests/sys/uspecs.sh-change-new.bats](../../../../../tests/sys/uspecs.sh-change-new.bats)
  - add: test for GitHub issue URL creates branch with issue-id prefix
  - add: test for GitLab issue URL creates branch with issue-id prefix
  - add: test for Jira issue URL creates branch with issue-id prefix
  - add: test for hash-fragment issue URL creates branch with issue-id prefix
  - add: test for issue URL with --no-branch does not create branch
  - add: test for GitHub issue URL with comment anchor extracts issue ID
  - add: test for issue URL with no valid issue ID falls back to change name
- [x] update: [tests/sys/uspecs.sh-pr-create.bats](../../../../../tests/sys/uspecs.sh-pr-create.bats)
  - add: test for decoding literal backslash-n in body to newlines
- [x] update: [tests/e2e/conf-install.bats](../../../../../tests/e2e/conf-install.bats)
  - add: test for alpha install with --nlic flag
  - add: test for alpha install with both --nlia and --nlic flags
