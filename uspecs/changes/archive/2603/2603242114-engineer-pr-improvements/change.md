---
registered_at: 2026-03-24T19:18:19Z
change_id: 2603241918-engineer-pr-improvements
baseline: 17428aeb54ce62a618b646cbdca96333f8c50d19
archived_at: 2026-03-24T21:14:24Z
---

# Change request: Improve upr and uaccept output structure

## Why

The upr and uaccept actions mix operational log output with agent instructions, making it hard for the calling agent to parse. Commands also hide stderr which makes failures hard to diagnose.

## What

Structured output for cmd_action_uaccept and cmd_action_upr:

- Introduce reusable `prompt_log` and `prompt_instructions` helper functions that wrap content in `<LOG>...</LOG>` and `<AGENT_INSTRUCTIONS>...</AGENT_INSTRUCTIONS>` tags
- Apply structured output to both cmd_action_uaccept and cmd_action_upr

Stop hiding command stderr in both actions:

- Remove `>/dev/null 2>&1` and `2>/dev/null` redirections from git and gh commands

Improvements to cmd_action_upr:

- After squash, push atexit handler to restore branch on failure; pop after force-push succeeds
- Include PR URL in the final upr_success instructions
- Skip squash when branch has exactly one commit since merge-base (avoid redundant force-push)
- Strip YAML frontmatter `---` delimiters as plain text instead of fenced yaml code block (backticks break GitHub PR creation URL)
