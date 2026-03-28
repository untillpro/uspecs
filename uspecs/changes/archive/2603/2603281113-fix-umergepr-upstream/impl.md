# Implementation plan: Fix umergepr upstream remote handling

## Construction

- [x] update: [uspecs.sh](../../../../u/scripts/uspecs.sh)
  - fix: Post-merge sync -- check ff feasibility with `git merge-base --is-ancestor`, log divergence details and skip if diverged, push to origin on success
- [x] update: [uspecs.sh](../../../../u/scripts/uspecs.sh)
  - add: After archive push, call `gh pr update-branch` to sync PR branch with latest base before `gh pr merge`
- [x] update: [uspecs.sh](../../../../u/scripts/uspecs.sh)
  - add: Explicit fork branch deletion via `git push origin --delete` after merge (with `git ls-remote` check)
- [x] update: [uspecs.sh](../../../../u/scripts/uspecs.sh)
  - add: Progress echo statements in cmd_action_upr and cmd_action_umergepr
  - update: Wrap all git/gh commands in both functions with `quiet` helper
- [x] add: [utils.sh](../../../../u/scripts/_lib/utils.sh)
  - add: `quiet()` helper -- captures stdout and stderr, suppresses on success, dumps to respective streams on failure
- [x] update: [gh](../../../../../tests/sys/stubs/gh)
  - add: Handle `pr update-branch` subcommand in gh stub
- [x] update: [uspecs.sh-prompt-umergepr.bats](../../../../../tests/sys/uspecs.sh-prompt-umergepr.bats)
  - add: Test for `gh pr update-branch` call during merge flow
  - update: Upstream remote test to verify no divergence warning
- [x] add: [utils-quiet.bats](../../../../../tests/unit/utils-quiet.bats)
  - add: 11 unit tests for `quiet` helper (suppression, dump-on-failure, exit code, argument passing)
- [x] update: [umergepr.feature](../../../../specs/prod/softeng/umergepr.feature)
  - update: PR update-branch step before merge
  - update: Upstream remote scenario with divergence detection, fork branch deletion, push to origin
- [x] Review
