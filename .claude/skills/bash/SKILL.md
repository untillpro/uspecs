---
name: bash
description: Use this skill when authoring or reviewing any `*.sh` file
user-invocable: false
---

# Bash

- When ShellCheck reports SC2016 for an intentional literal string in single quotes, keep the single-quoted literal and add a targeted `# shellcheck disable=SC2016` comment explaining why expansion is intentionally disabled.
