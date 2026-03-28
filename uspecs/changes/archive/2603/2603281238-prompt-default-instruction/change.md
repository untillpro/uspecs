---
registered_at: 2026-03-28T11:42:59Z
change_id: 2603281142-prompt-default-instruction
baseline: 07c51099c7046eb95bbdb2c49a1bdd18900ab6e7
archived_at: 2026-03-28T12:38:13Z
---

# Change request: Default agent instruction in prompt output

## Why

When scripts finish successfully without providing explicit AGENT_INSTRUCTIONS content, agents have no guidance on what to tell the user. They end up parroting raw output, duplicating information, or adding unsolicited commentary instead of simply informing the user about results.

## What

- Rename `prompt_finish_log_start_instructions` to `prompt_start_instructions` - symmetric with `prompt_start_log`
- Emit a default meta-instruction ("Inform user about the results, see below.") when no parameter given, or a custom meta-instruction when parameter is provided
- Auto-close `</AGENT_INSTRUCTIONS>` via atexit handler - eliminates the need for callers to call `prompt_finish_instructions`
- Remove `prompt_finish_instructions`
- Add scenario for successful script execution to script-execution.feature
