# Implementation plan: Error Ask User Options

## Functional design

- [x] create: [softeng/shared/script-execution.feature](../../specs/prod/softeng/shared/script-execution.feature)
  - add: Scenario "Script exits with error" - when AI Agent runs a script and interprets its output, and the script exits with error, agent presents full error output to Engineer, suggests recovery options, and waits for explicit Engineer permission before any further action

## Construction

- [x] update: [u/scripts/_lib/utils.sh](../../u/scripts/_lib/utils.sh)
  - update: `_prompt_close_log_on_exit` to emit `<AGENT_INSTRUCTIONS>` with error handling instructions via `echo` after `</LOG>`
- [x] create: [tests/unit/utils-prompt.bats](../../../tests/unit/utils-prompt.bats)
  - add: tests for script error output contract - `<AGENT_INSTRUCTIONS>` present when script exits with error after `prompt_start_log`, absent on success
