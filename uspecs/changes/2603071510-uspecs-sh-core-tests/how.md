# How: Core tests for uspecs.sh

## Approach

- Use `bats` (Bash Automated Testing System) as the test framework - already available in the environment (v1.13.0)
- Place test files in `tests/` at the repository root
- Two test levels, each in its own `.bats` file:
  - System tests (`uspecs.sh.bats`): exercise `uspecs.sh` as a black box with real git (local bare repos) and `gh` CLI stubbed; no real GitHub access needed
  - E2e tests (`uspecs.sh-e2e.bats`): exercise `uspecs.sh` with real git and real `gh` CLI against a dedicated GitHub test repo; require `USPECS_GH_TOKEN` and test repo config (future scope)
- Each test invokes `uspecs.sh` via `run bash uspecs/u/scripts/uspecs.sh ...` and asserts on `$status` and `$output`
- Use bats `setup` / `teardown` to create and remove a temporary directory (`$BATS_TEST_TMPDIR`) used as an isolated project root
- System tests stub `gh` by placing a recording script earlier on `PATH` in `setup` that records args to `gh.calls` and stdin to `gh.body`, prints a fake PR URL and exits 0
- The `conf.md` path resolution inside `uspecs.sh` is based on the script's own location, so tests symlink or copy `uspecs/u/conf.md` into the temp project structure

Developer workflow:

- System tests: `bats tests/uspecs.sh.bats`
- E2e tests: `bats tests/uspecs.sh-e2e.bats` (requires `USPECS_GH_TOKEN`)

References:

- [uspecs/u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)
- [uspecs/u/scripts/_lib/utils.sh](../../u/scripts/_lib/utils.sh)
- [uspecs/u/conf.md](../../u/conf.md)
