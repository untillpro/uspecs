# Decisions

## Action file location: uspecs/u/clarify.md

Decision: Create action file at uspecs/u/clarify.md

Rationale:

- Follows the pattern of other action files (fd.md, td.md, changes.md) in uspecs/u/
- Consistent with existing structure
- Easy to reference from main.md
- No need to create new folder structure

Alternatives considered:

- uspecs/u/actions/clarify.md - Rejected because it requires creating new folder structure and doesn't match existing pattern
- Integrate into uspecs/u/changes.md - Rejected because it reduces modularity and makes the file harder to maintain

## Question identification: AI-driven analysis

Decision: Use AI-driven analysis to identify ambiguities and uncertainties

Rationale:

- More flexible than pattern-based detection
- Can identify context-specific ambiguities that patterns might miss
- Leverages AI agent's general intelligence
- Better suited for diverse change types (technical, functional, documentation, etc.)
- Can adapt to different levels of detail in change descriptions

Alternatives considered:

- Pattern-based detection - Rejected because it's too rigid and may miss context-specific ambiguities
- User-guided selection - Rejected because it requires additional interaction step and defeats the purpose of automated identification

## decisions.md structure: DDD pattern

Decision: Follow DDD decisions.md pattern from rsch/251210-ddd/decisions.md and add template section to uspecs/u/templates.md

Rationale:

- Proven structure with clear sections
- Includes decision title, decision statement, rationale, examples, and alternatives considered
- Well-documented format that's easy to scan and understand
- Comprehensive enough to capture reasoning without being overly formal
- Matches existing pattern in the codebase
- Using templates.md registry avoids creating separate template file (follows existing pattern)

Structure:

```markdown
## Decision Title

Decision: Brief decision statement

Rationale:

- Reason 1
- Reason 2

Examples: (if applicable)

Alternatives considered:

- Alternative A - Rejection reason
- Alternative B - Rejection reason
```

Alternatives considered:

- Simplified format (title + description only) - Rejected because it lacks rationale and alternatives, making it harder to understand the reasoning
- ADR format (Status, Context, Decision, Consequences) - Rejected because it's too formal and may be overkill for simple decisions

