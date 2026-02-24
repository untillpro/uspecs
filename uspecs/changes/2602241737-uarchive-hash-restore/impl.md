# Implementation plan: Uarchive report deleted branch hash and restore

## Functional design

- [x] update: [prod/softeng/uarchive.feature](../../specs/prod/softeng/uarchive.feature)
  - update: "Archive change request on PR branch" scenario - add step that branch hash is reported after deletion on option 1

## Technical design

- [x] update: [prod/softeng/softeng--arch.md](../../specs/prod/softeng/softeng--arch.md)
  - update: uarchive output entry - add deleted branch hash and restore instructions to reported output

## Construction

- [x] update: [u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)
  - add: capture branch hash before deletion in `cmd_change_archive`
  - add: print hash and `git branch <branch-name> <hash>` restore hint after branch is deleted

- [x] update: [u/actn-uarchive.md](../../u/actn-uarchive.md)
  - update: flow step for option 1 output - note that script reports deleted branch hash and restore instructions to relay to Engineer
