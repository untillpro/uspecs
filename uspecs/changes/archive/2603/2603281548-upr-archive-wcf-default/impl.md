# Implementation plan: Archive WCF by default in upr action

## Construction

- [x] update: [softeng.sh](../../../../u/scripts/softeng.sh)
  - update: cmd_action_upr to parse --no-archive flag
  - add: WCF archiving step (active WCF only) before squash/push, skipped when --no-archive or WCF already archived
  - update: script usage comment to document --no-archive flag
- [x] update: [softeng.sh-prompt-upr.bats](../../../../../tests/sys/softeng.sh-prompt-upr.bats)
  - add: test that WCF is archived by default after upr
  - update: existing "WCF is active" test to reflect new archiving behavior
  - add: test that --no-archive flag keeps WCF active
  - add: test that already-archived WCF is not re-archived
