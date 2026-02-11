# Technical design: Interactive clarification with three questions

## Overview

This design implements an "ask questions" action that identifies ambiguities and uncertainties in Active Change Folder files, asks three targeted questions with suggested solutions, and integrates answers back into the appropriate files. The action uses AI-driven analysis to identify unclear aspects and follows the DDD decisions.md pattern for documenting choices.

The action supports:

- Optional area/scope parameter to focus questions on specific aspects
- Web search integration when it may help formulate or answer questions
- Mandatory web search when explicitly requested by user

## File updates

### Action file

- [x] create: `[clarify.md](../../u/clarify.md)`
  - Action definition for "ask questions" workflow
  - Parameters:
    - Active Change Folder path (optional, inferred from context)
    - Area/scope specification (optional, focuses questions on specific aspect)
    - Web search flag (optional, forces web search)
  - Flow: Identify folder, analyze files, conduct web search if needed/requested, ask 3 questions, integrate answers
  - Question identification: AI-driven analysis of ambiguities and uncertainties
  - Web search: Conducted when it may help or when explicitly requested by user
  - Answer integration: Fix ambiguities in source files, document choices in decisions.md

### Main action registry

- [x] update: `[main.md](../../u/main.md)`
  - Add "Ask questions" section after "Apply todo items"
  - Reference: Use rules from uspecs/u/clarify.md

### Triggering instructions

- [x] update: `[AGENTS.md](../../../AGENTS.md)`
  - Add "ask questions" to triggering instructions list
  - Insert in triggering_instructions section between existing triggers

### Templates registry

- [x] update: `[templates.md](../../u/templates.md)`
  - Add decisions.md template section
  - Include structure, rules, and example

## Quick start

Ask questions about the current change:

```bash
# User says:
ask questions

# Or focus on specific area:
ask questions about technical implementation

# Or force web search:
ask questions with web search
```

Agent will:

1. Identify Active Change Folder from context
2. Conduct web search if it may help or if explicitly requested
3. Analyze all files in the folder (or focus on specified area)
4. Ask 3 questions with suggested solutions
5. Wait for answers
6. Integrate answers:
   - Fix ambiguities directly in change files
   - Document choices in decisions.md

## References

- `[change.md](change.md)` - Change description
- `[rsch/251210-ddd/decisions.md](../../../../rsch/251210-ddd/decisions.md)` - decisions.md pattern reference
- `[uspecs/u/td.md](../../u/td.md)` - Existing clarification mechanism in technical design
