# Issue file format

## data

```markdown
# {issue title}

- URL: {issue_url}
- ID: {issue_id} (e.g. `#42`, `PROJ-123`)
- State: {open|closed|merged|in-progress|...}
- Author: {@handle or display name}
- Labels: {comma-separated, or `none`}
- [optional, add as additional bullets above when available: Assignees, Milestone, Closed at, Linked PRs/issues]

{issue body verbatim with these rules:
 - if the body starts with a `#`-prefixed heading, keep it as-is
 - otherwise prepend `## Description` so the document stays well-formed
 - demote any leading `# ` heading in the source body to `## ` to avoid a duplicate H1}
```
