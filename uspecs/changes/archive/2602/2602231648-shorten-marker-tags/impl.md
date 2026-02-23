# Implementation plan: Shorten uspecs marker tags

## Construction

- [x] update: [u/scripts/conf.sh](../../../../u/scripts/conf.sh)
  - update: `inject_instructions()` -- use `<!-- uspecs:begin -->` / `<!-- uspecs:end -->` as primary markers; detect old `<!-- uspecs:triggering_instructions:begin/end -->` in both source and target files; upgrade old markers to new format in output
  - update: `remove_instructions()` -- use new markers as primary; also detect and remove content wrapped in old markers

- [x] update: [AGENTS.md](../../../../../AGENTS.md)
  - update: replace `<!-- uspecs:triggering_instructions:begin -->` with `<!-- uspecs:begin -->`
  - update: replace `<!-- uspecs:triggering_instructions:end -->` with `<!-- uspecs:end -->`

- [x] update: [CLAUDE.md](../../../../../CLAUDE.md)
  - update: replace `<!-- uspecs:triggering_instructions:begin -->` with `<!-- uspecs:begin -->`
  - update: replace `<!-- uspecs:triggering_instructions:end -->` with `<!-- uspecs:end -->`
