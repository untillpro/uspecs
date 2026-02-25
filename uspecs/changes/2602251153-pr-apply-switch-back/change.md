---
registered_at: 2026-02-25T11:53:53Z
change_id: 2602251153-pr-apply-switch-back
baseline: 3ae1eedce4ac7c85de33e2f621ef820b07b4ea79
---

# Change request: conf.sh cmd_apply should switch back to original branch after sending PR

## Why

When `cmd_apply` is called on a PR branch, it needs to switch to the default branch, fast-forward it, and then switch back to the original branch. Currently `cmd_ffdefault` in `pr.sh` switches back to the original branch immediately after fast-forwarding, instead of letting the caller control the return flow.
