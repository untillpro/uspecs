# Implementation plan: pr mergedef --validate should try to merge

## Construction

- [x] update: [scripts/_lib/pr.sh](../../u/scripts/_lib/pr.sh)
  - remove: `--validate` flag and its entire code path from `cmd_mergedef`
  - update: `cmd_mergedef` -- capture `change_branch_head` (HEAD sha) before fetch; after successful merge output `change_branch=...`, `default_branch=...`, `change_branch_head=...`
  - update: `mergedef` header comment to document output key=value lines; remove `[--validate]` from usage

- [x] update: [actn-upr.md](../../u/actn-upr.md)
  - remove: separate `--validate` precondition step
  - reorder: `mergedef` is now the first step, before reading change folder and presenting confirmation
  - update: `mergedef` step now parses `change_branch`, `default_branch`, `change_branch_head` from output

- [x] update: [scripts/uspecs.sh](../../u/scripts/uspecs.sh)
  - update: `pr mergedef` header comment to document output key=value lines
  