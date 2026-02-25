# How: pr.sh cmd_apply should switch back to original branch after sending PR

## Approach

- Fix `cmd_ffdefault` in `pr.sh`: remove the switch-back block and its cleanup trap so the command
  stays on the default branch after fast-forwarding. This makes it a clean primitive: switch to
  default if needed, fetch, fast-forward, done.

- Fix `cmd_apply` in `conf.sh`: move the `prev_branch` capture to before the `ffdefault` call.
  Currently it is captured after `ffdefault` has already switched back, which is redundant and
  obscures intent. With `ffdefault` no longer switching back, the correct branch is captured before
  any switching occurs, and `pr.sh pr --next-branch "$prev_branch"` (already present) handles the
  final switch-back.

References:

- [uspecs/u/scripts/_lib/pr.sh](../../../../u/scripts/_lib/pr.sh)
- [uspecs/u/scripts/conf.sh](../../../../u/scripts/conf.sh)
