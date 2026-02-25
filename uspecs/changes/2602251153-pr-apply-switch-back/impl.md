# Implementation plan: conf.sh cmd_apply should switch back to original branch after sending PR

## Construction

- [x] update: [uspecs/u/scripts/_lib/pr.sh](../../u/scripts/_lib/pr.sh)
  - fix: remove switch-back block (lines 211-215) and its cleanup trap (line 200) from `cmd_ffdefault` so it stays on the default branch after fast-forwarding

- [x] update: [uspecs/u/scripts/conf.sh](../../u/scripts/conf.sh)
  - fix: move `prev_branch` capture in `cmd_apply` to before the `ffdefault` call so the original branch is remembered before any switching occurs

- [x] update: [uspecs/u/scripts/conf.sh](../../u/scripts/conf.sh)
  - add: ERR trap in `cmd_apply` after `ffdefault` succeeds to switch back to `prev_branch` on failure; clear trap after `pr.sh pr` succeeds
