---
registered_at: 2026-03-25T16:42:45Z
change_id: 2603251642-error-ask-user-options
baseline: c193fa970552d2b325b8f2440423ea363d619615
---

# Change request: Error Ask User Options

## Why

When `uspecs.sh` exits with an error, the agent currently attempts to diagnose and fix the problem autonomously. This violates the principle that the agent must not take actions without explicit user permission, and can lead to unintended side effects.

## What

Update `uspecs/u/actn-uchange.md` so that on script error the agent stops, presents the error to the user, and waits for explicit instruction:

- Replace the "Fail fast if script exits with error" instruction with explicit guidance to:
  - Show the full error output to the user
  - Suggest recovery options (e.g. fix input and retry, retry with different flags, abort)
  - Never take any further action until the user explicitly chooses an option
