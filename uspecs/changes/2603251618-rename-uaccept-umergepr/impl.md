# Implementation plan: Rename uaccept to umergepr

## Construction

- [x] update: [scripts/uspecs.sh](../../u/scripts/uspecs.sh)
  - rename: action keyword `uaccept` to `umergepr`
  - rename: function `cmd_action_uaccept` to `cmd_action_umergepr`
  - update: error message listing available action keywords
  - update: internal comment on `cmd_action_uaccept`

- [x] update: [scripts/prompts.md](../../u/scripts/prompts.md)
  - rename: all `uaccept_*` section identifiers to `umergepr_*`
  - update: prose occurrences of `uaccept` to `umergepr`
