# Implementation plan: Check command availability in all scripts

## Construction

- [x] create: [u/scripts/_lib/utils.sh](../../../../../../u/scripts/_lib/utils.sh)
  - add: `checkcmds command1...` function — checks each argument with `command -v`, prints error naming the missing command, exits non-zero on first failure
- [x] update: [u/scripts/uspecs.sh](../../../../../../u/scripts/uspecs.sh)
  - add: source `_lib/utils.sh` and call `checkcmds` for required commands (`grep`, `wc`, `sed`, `find`, `awk`, `mktemp`, `date`, `git`) at startup
- [x] update: [u/scripts/conf.sh](../../../../../../u/scripts/conf.sh)
  - add: source `_lib/utils.sh` and call `checkcmds` for required commands (`curl`, `tar`, `grep`, `sed`, `find`, `awk`, `mktemp`, `date`, `git`) at startup
