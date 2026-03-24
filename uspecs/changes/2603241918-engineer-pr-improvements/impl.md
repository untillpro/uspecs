# Implementation plan: Improve upr and uaccept output structure

## Construction

### Helper functions

- [x] update: [_lib/utils.sh](../../u/scripts/_lib/utils.sh)
  - add: `prompt_start_log` function - emits `<LOG>`
  - add: `prompt_finish_log_start_instructions` function - emits `</LOG>\n<AGENT_INSTRUCTIONS>`
  - add: `prompt_finish_instructions` function - emits `</AGENT_INSTRUCTIONS>`

### cmd_action_uaccept

- [x] update: [uspecs.sh](../../u/scripts/uspecs.sh) `cmd_action_uaccept`
  - update: call `prompt_start_log` before operational output (git fetch, archive, merge)
  - update: call `prompt_finish_log_start_instructions` before `section_templ` agent instructions
  - update: call `prompt_finish_instructions` at end of function
  - update: remove stderr suppression (`>/dev/null 2>&1`, `2>/dev/null`) from git and gh commands

### cmd_action_upr

- [x] update: [uspecs.sh](../../u/scripts/uspecs.sh) `cmd_action_upr`
  - update: call `prompt_start_log` before operational output
  - update: call `prompt_finish_log_start_instructions` before `section_templ` agent instructions
  - update: call `prompt_finish_instructions` at end of function
  - update: remove stderr suppression from git and gh commands
  - add: `atexit_push` handler after squash to restore branch on failure; `atexit_pop` after force-push succeeds
  - add: capture PR URL via `gh pr view --json url` for OPEN case, pass as `${pr_url}` to upr_already_exists template
  - remove: PR URL capture from `gh pr create --web` (does not return URL)
  - add: count commits between merge-base and HEAD; skip squash+force-push when count is 1 (plain `git push` instead)
  - add: select `upr_success_no_squash` prompt when squash is skipped, `upr_success` when squash occurs
  - fix: strip YAML frontmatter `---` delimiters instead of replacing with fenced yaml code block (backticks break GitHub PR URL)
  - fix: replace `2>&1` with `2>/dev/null` in `gh pr view` existence check; remove `2>&1` from other `gh pr view` calls inside command substitutions

### Prompts

- [x] update: [prompts.md](../../u/scripts/prompts.md) `upr_already_exists` section
  - add: `${pr_url}` variable to display PR URL when PR already exists
- [x] update: [prompts.md](../../u/scripts/prompts.md) `upr_success` section
  - remove: `${pr_url}` (not available from `gh pr create --web`)
  - add: restore instructions (`${pre_push_head}`) to revert squash
- [x] add: [prompts.md](../../u/scripts/prompts.md) `upr_success_no_squash` section
  - next steps without restore instructions (used when squash is skipped)
- [x] update: [prompts.md](../../u/scripts/prompts.md) `uaccept_success` section
  - add: restore instructions (`${branch_head}`) to recover local branch
- [x] update: [prompts.md](../../u/scripts/prompts.md) cleanup
  - remove: dead `upr_restore` section (restore instructions moved into `upr_success`)
  - update: add `instructions:` / `info:` labels to section headers

### cmd_action_uaccept (restore instructions and stderr fix)

- [x] update: [uspecs.sh](../../u/scripts/uspecs.sh) `cmd_action_uaccept`
  - add: capture `branch_head` before merge, pass to `uaccept_success` template
  - fix: replace `2>&1` with `2>/dev/null` in `gh pr view` existence check; remove `2>&1` from `gh pr view --json number` call

### Feature specs

- [x] update: [upr.feature](../../specs/prod/softeng/upr.feature)
  - update: OPEN action shows PR URL
  - remove: "Engineer is provided with PR URL" from "No PR" scenario
  - add: Engineer is provided with restore instructions to revert the squash
  - add: split "No PR" scenario into single-commit (squash skipped) and multiple-commits (squash performed)
  - update: pr_body description - frontmatter delimiters stripped as plain text instead of fenced yaml code block
  - update: commit message format only applies when squashing (multiple commits)
- [x] update: [uaccept.feature](../../specs/prod/softeng/uaccept.feature)
  - add: Engineer is provided with restore instructions to recover local branch

### Tests

- [x] update: [uspecs.sh-prompt-upr.bats](../../../tests/sys/uspecs.sh-prompt-upr.bats)
  - update: assertions to check for `<LOG>` and `<AGENT_INSTRUCTIONS>` tags
  - update: assertions that check prompt content to look inside `<AGENT_INSTRUCTIONS>`
  - remove: dead `upr_restore` assertions
  - add: "single commit, squash skipped" test - verifies `upr_success_no_squash` prompt and no `git reset --hard`
  - add: "multiple commits squashed" test - verifies `upr_success` prompt with restore instructions
  - update: PR body assertions - check for plain text frontmatter fields and absence of backticks/delimiters
  - remove: commit message assertions from single-commit tests (message only rewritten when squashing)

- [x] update: [uspecs.sh-prompt-uaccept.bats](../../../tests/sys/uspecs.sh-prompt-uaccept.bats)
  - update: assertions to check for `<LOG>` and `<AGENT_INSTRUCTIONS>` tags
  - update: assertions that check prompt content to look inside `<AGENT_INSTRUCTIONS>`
  - [x] add: restore instructions assertion to "PR in OPEN state" test
