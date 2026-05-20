# Self-review: construction (Stage B)

## data

Review the construction artifacts that were just changed (or added) by `uimpl` for:

- DRY (no duplicated logic or constants)
- SOLID principles (single responsibility, open/closed, etc.)

Rules:

- For each issue found, fix it inline; do not stop to ask the user
- Do not re-run this stage

After fixing all issues:

- Run `bash bin/softeng.sh self-review --type construction --stage C --concurrency` (?concurrency)
- Report results to the user: files reviewed, issues found, fixes applied, and any outstanding issues (?!concurrency)
