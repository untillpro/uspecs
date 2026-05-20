# Self-review: specs (Stage A)

## data

Review the specs and/or to-do items that were just changed (or added) by `uimpl` or `uchange` for:

- Consistency with the change request
- DRY across specs - no duplicated requirements, scenarios etc. Replace with references whenever possible.
- If new section has been created check that you have not missed anything (modify tests, cover requirements, etc.)

Rules:

- For each issue found, fix it inline; do not stop to ask the user
- If issues were detected during this review, re-invoke this stage: `bash "${softeng_sh}" self-review --type specs --stage A -b ${next_budget}` (?budget)
- If no new issues were detected during this review, report results to the user: files reviewed, issues found, fixes applied, and any outstanding issues
