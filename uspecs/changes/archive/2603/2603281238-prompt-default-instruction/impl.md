# Implementation plan: Default agent instruction in prompt output

## Functional design

- [x] update: [shared/script-execution.feature](../../../../specs/prod/softeng/shared/script-execution.feature)
  - add: Scenario for successful script execution - agent follows instructions in the output

## Construction

- [x] update: [_lib/utils.sh](../../../../u/scripts/_lib/utils.sh)
  - rename: `prompt_finish_log_start_instructions` -> `prompt_start_instructions`
  - add: Optional meta-instruction parameter; default is "Inform user about the results, see below."
  - add: `_PROMPT_INSTR_OPEN` flag and atexit auto-close for `</AGENT_INSTRUCTIONS>`
  - rename: `_prompt_close_log_on_exit` -> `_prompt_close_tags_on_exit`, handles both LOG and AGENT_INSTRUCTIONS
  - remove: `prompt_finish_instructions`
- [x] update: [softeng.sh](../../../../u/scripts/softeng.sh)
  - rename: All callers to use `prompt_start_instructions`
  - remove: All `prompt_finish_instructions` calls (auto-closed by atexit)
- [x] update: [utils-prompt.bats](../../../../../tests/unit/utils-prompt.bats)
  - update: Tests to use `prompt_start_instructions` with atexit auto-close
  - add: Test for custom meta-instruction replacing default
