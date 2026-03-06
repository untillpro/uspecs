# Implementation plan: upr fails on open todo items

## Functional design

- [x] update: [softeng/upr.feature](../../specs/prod/softeng/upr.feature)
  - add: "change folder has uncompleted todo items" to "Validation rejects invalid state" examples

## Construction

- [x] update: [u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)
  - rename: `pr mergedef` subcommand to `pr preflight`
  - add: `--change-folder <path>` option to `pr preflight` subcommand
  - add: uncompleted todo items check using the provided change folder path, fail with error if any `- [ ]` items found

- [x] update: [u/actn-upr.md](../../u/actn-upr.md)
  - rename: `pr mergedef` to `pr preflight` in the Flow step
  - add: pass Active Change Folder path via `--change-folder` option
