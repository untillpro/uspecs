# Implementation plan: Update upr features

## Functional design

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: pr_body truncation rule from 4000-character limit to 40-line limit

## Construction

- [x] update: [softeng.sh](../../../../u/scripts/softeng.sh)
  - update: replace 4000-character truncation with 40-line truncation in cmd_action_upr
- [x] update: [softeng.sh-prompt-upr.bats](../../../../../tests/sys/softeng.sh-prompt-upr.bats)
  - update: truncation test to generate content exceeding 40 lines and assert line-based truncation instead of character-based
