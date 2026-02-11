---
registered_at: 2026-02-05T17:18:03Z
change_id: 2602051817-uhow-top-uncertainties
baseline: b9f79aea8a2c44ff9d45188a782c3ae66687498b
archived_at: 2026-02-07T17:11:49Z
---

# Change request: uhow identifies top 5 uncertainties

## Why

Engineer needs to see the most critical uncertainties first when running uspecs-how command. Currently the command identifies 3 uncertainties, but this may not be enough to cover all important aspects. Additionally, the command has complex logic with predefined sections and flags that creates unnecessary complexity.

## What

Simplified uhow behavior:

- AI Agent identifies top 5 uncertainties (instead of 3) in the Change Request that are not yet covered by how.md
- AI Agent writes uncertainties to how.md, grouping them by topic when appropriate
- Engineer can optionally specify area of focus using natural language (e.g., "focus on authentication", "clarify database design")
- Remove all predefined sections (functional design, technical design, provisioning, construction) and their associated flags
