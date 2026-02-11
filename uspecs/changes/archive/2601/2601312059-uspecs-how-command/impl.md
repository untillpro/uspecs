# Implementation: uspecs-how command

## Functional design

- [x] create: [prod/softeng/how.feature](../../../../specs/prod/softeng/how.feature)
  - add: Scenario Outline for Execute uspecs-how command with conditions and actions

## Construction

- [x] create: [uspecs/u/actn-how.md](../../../../u/actn-how.md)
  - add: Rules, definitions, and scenarios for uhow command
- [x] create: [uspecs/u/templates-how.md](../../../../u/templates-how.md)
  - add: Template for How File structure
- [x] modify: [uspecs/u/conf.md](../../../../u/conf.md)
  - add: How File artifact definition
- [x] modify: AGENTS.md, CLAUDE.md
  - add: uhow trigger instruction

## Quick start

Run uspecs-how to document the project:

```text
uhow
```

AI Agent will ask questions about the project and write answers to how.md.
