# Implementation plan: Use action command instead of prompt for upr and uaccept

## Construction

- [x] update: [AGENTS.md](../../../../../AGENTS.md)
  - update: Change `uspecs.sh prompt {keyword}` to `uspecs.sh action {keyword}` in execution instructions
- [x] update: [uspecs/u/scripts/uspecs.sh](../../../../../uspecs/u/scripts/uspecs.sh)
  - update: Rename `prompt` command to `action` in main command dispatcher
  - update: Update usage documentation comments to use `action` instead of `prompt`
- [x] update: [tests/sys/uspecs.sh-prompt-upr.bats](../../../../../tests/sys/uspecs.sh-prompt-upr.bats)
  - update: Replace all `uspecs prompt upr` calls with `uspecs action upr`
  - update: Update test names from "prompt upr" to "action upr"
- [x] update: [tests/sys/uspecs.sh-prompt-uaccept.bats](../../../../../tests/sys/uspecs.sh-prompt-uaccept.bats)
  - update: Replace all `uspecs prompt uaccept` calls with `uspecs action uaccept`
  - update: Update test names from "prompt uaccept" to "action uaccept"
