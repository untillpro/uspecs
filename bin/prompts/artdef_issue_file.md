# Issue file format

## data

```markdown
# {issue title}

- URL: {issue_url}
- ID: {issue_id} (e.g. `#42`, `PROJ-123`)
- State: {open|closed|merged|in-progress|...}
- Author: {user-readable handle or display name}
- Labels: {comma-separated, or `none`}
- [optional, add as additional bullets above when available: Assignees, Milestone, Closed at, Linked PRs/issues]

{issue body verbatim with these rules:
 - if the body starts with a `#`-prefixed heading, keep it as-is
 - otherwise prepend `## Description` so the document stays well-formed
 - demote any leading `# ` heading in the source body to `## ` to avoid a duplicate H1}
```

Rules:

- Author is a user-facing field; use user-readable handles or display names, not provider account IDs, UUIDs, or opaque API identifiers
- Good: `- Author: @jane-doe (Jane Doe)` or `- Author: Jane Doe`
- Bad: `- Author: 712020:86e96e83-1214-4b40-8828-64fef3dc2280`
- If only an opaque ID is available, do not invent a name; write `Unknown user name ({opaque-id})`
