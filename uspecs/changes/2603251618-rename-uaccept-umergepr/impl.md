# Implementation plan: Rename uaccept to umergepr

## Technical design

- [x] update: [specs/prod/softeng/arch.md](../../specs/prod/softeng/arch.md)
  - add: `umergepr` entry to examples list

## Functional design

- [x] rename: `specs/prod/softeng/uaccept.feature` -> [specs/prod/softeng/umergepr.feature](../../specs/prod/softeng/umergepr.feature)
  - update: feature title and description from "accept" to "merge" wording
  - update: all scenario steps from `uaccept action` to `umergepr action`

## Construction

- [x] update: [u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)
  - rename: action keyword `uaccept` to `umergepr`
  - rename: function `cmd_action_uaccept` to `cmd_action_umergepr`
  - update: error message listing available action keywords

- [x] update: [u/scripts/prompts.md](../../u/scripts/prompts.md)
  - rename: all `uaccept_*` section identifiers to `umergepr_*`
  - update: prose occurrences of `uaccept` to `umergepr`

- [x] update: [AGENTS.md](../../../AGENTS.md), [CLAUDE.md](../../../CLAUDE.md)
  - update: execution instructions keyword list from `uaccept` to `umergepr`

- [x] rename: `tests/sys/uspecs.sh-prompt-uaccept.bats` -> [tests/sys/uspecs.sh-prompt-umergepr.bats](../../../tests/sys/uspecs.sh-prompt-umergepr.bats)
  - update: all helper names, test names, action keywords, and prompt section assertions

- [x] update: [tests/unit/utils-md.bats](../../../tests/unit/utils-md.bats)
  - update: fixture data strings from `uaccept` to `umergepr`
