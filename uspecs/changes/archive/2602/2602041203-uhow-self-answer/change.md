---
registered_at: 2026-02-03T17:52:58Z
change_id: 2602031852-uhow-self-answer
baseline: c9d88667fadb40ea633fc4ae75932321eb57bde3
archived_at: 2026-02-04T12:03:01Z
---

# Change request: uhow command self-answers uncertainties

## Why

When Engineer runs uspecs-how command, the AI Agent should autonomously identify uncertainties, solve them, and write the results directly to how.md. This reduces back-and-forth interaction and provides immediate value.

## What

Modified uhow behavior:

- AI Agent identifies three uncertainties in the Change Request
- AI Agent answers each uncertainty itself (instead of asking Engineer)
- AI Agent writes questions, answers, and alternatives directly to how.md
