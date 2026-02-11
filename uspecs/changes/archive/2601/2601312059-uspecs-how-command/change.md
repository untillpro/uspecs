---
registered_at: 2026-01-31T20:03:06Z
change_id: 2601312102-uspecs-how-command
baseline: 22c11ac150b942542f6902afab7e402a8f34f7d1
archived_at: 2026-01-31T20:59:54Z
---

# Change request: uspecs-how command

## Why

Engineer needs a guided way to clarify and brainstorm Change Request functional and technical design.

## What

New `uspecs-how` command that guides Engineer through questions and writes results to `how.md`:

- Add `uspecs-how` command to uspecs CLI
- Command asks Engineer a series of questions about the project
- Collects answers interactively
- Writes collected information to `how.md` file in project root
