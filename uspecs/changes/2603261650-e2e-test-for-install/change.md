---
registered_at: 2026-03-26T16:50:37Z
change_id: 2603261650-e2e-test-for-install
baseline: 73e9934d0a8456fc9400f16379e0312e39e70e3d
---

# Change request: E2E test for install

## Why

The README install command (`curl ... | bash -s install ...`) fails because conf.sh unconditionally sources `_lib/git.sh` at load time, which requires `BASH_SOURCE[0]` to resolve to a file. When piped, `BASH_SOURCE[0]` is unavailable.

## What

Fix curl-pipe install and add e2e test:

- Make conf.sh skip sourcing `_lib/git.sh` when piped (BASH_SOURCE[0] is not a file)
- The piped cmd_install path uses only curl, mktemp, trap, and bash builtins
- The downloaded conf.sh apply runs from a file and sources normally
- Add e2e test for curl-pipe alpha install
