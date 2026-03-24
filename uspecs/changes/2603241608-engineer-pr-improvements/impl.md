# Implementation plan: Engineer PR Improvements

## Functional design

- [x] update: [softeng/upr.feature](../../specs/prod/softeng/upr.feature)
  - update: WCF is not archived when Engineer creates a PR
  - update: PR body is taken from change.md
  - update: commit message references change.md without path

## Construction

- [x] update: [scripts/uspecs.sh](../../../uspecs/u/scripts/uspecs.sh)
  - remove: WCF archival block from cmd_action_upr
  - update: pr_body to be read from change.md content
  - update: see_details_line to use "change.md" without path
- [x] update: [stubs/gh](../../../tests/sys/stubs/gh)
  - update: --body-file handling to read from file path argument instead of stdin
- [x] update: [uspecs.sh-prompt-upr.bats](../../../tests/sys/uspecs.sh-prompt-upr.bats)
  - update: "WCF is active" test to assert WCF remains active (not archived)
  - update: commit message tests to expect "See change.md for details" without path
  - add: pr_body assertions to verify change.md content is passed via --body-file
