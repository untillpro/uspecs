# Self-review: construction (Stage C)

## data

Review the construction artifacts that were just changed (or added) by `uimpl` for concurrency issues:

- Race conditions
- Deadlocks
- Improper synchronization or ordering assumptions
- Unsafe shared state

Rules:

- For each issue found, fix it inline; do not stop to ask the user
- Do not re-run this stage
- After fixing all issues, report results to the user: files reviewed, issues found, fixes applied, and any outstanding issues
