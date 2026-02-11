---
registered_at: 2026-02-02T11:15:03Z
change_id: 2602021214-optional-web-search-uhow
baseline: cf31cf4f0b1729ee78396f5bc1adbe3f69a640bf
archived_at: 2026-02-02T11:28:42Z
---

# Change request: Optional web search for uhow command

## Why

The uhow command currently mandates web search before asking questions, which may not always be necessary or desired. Users should have control over when web search is performed, using it only when they explicitly request it or when it would genuinely help with clarification.

## What

Make web search optional for uhow command instead of mandatory:

- Web search is performed when Engineer explicitly requests it with --web flag or mentions using web search
- Default behavior performs web search automatically for complicated cases (technology/algorithm/pattern choices), otherwise asks questions without web search
- Maintains existing question format and structure (3 questions with numbered options)

Files to update:

- uspecs/u/actn-how.md: Change web search rule from mandatory to optional
- uspecs/specs/prod/softeng/how.feature: Update Background to reflect conditional web search behavior
