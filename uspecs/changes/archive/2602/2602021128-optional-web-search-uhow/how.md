# How: Optional web search for uhow command

## Functional design

### Q: How should Engineer specify that they want web search enabled for uhow command?

A: Both flag and natural language should work

Alternatives:

- Use --web flag only (e.g., "uhow --web")
- Use natural language mention only (e.g., "uhow with web search" or "uhow use web search")

### Q: What should be the default behavior when Engineer runs uhow without specifying web search preference?

A: Perform web search on complicated cases like which tech/algorithm to choose

Alternatives:

- Skip web search entirely and ask questions based only on existing context
- Ask user whether to perform web search before proceeding

### Q: Should the web search behavior be configurable per question type (functional vs technical)?

A: No, web search flag applies to all questions uniformly

Alternatives:

- Allow separate flags like --web-functional and --web-technical
- Infer automatically based on question complexity
