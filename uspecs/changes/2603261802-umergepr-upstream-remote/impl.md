# Implementation plan: umergepr scenario for upstream remote

## Functional design

- [x] update: [softeng/umergepr.feature](../../specs/prod/softeng/umergepr.feature)
  - add: Scenario "Default: upstream remote exists"
- [x] update: [conf/install.feature](../../specs/prod/conf/install.feature)
  - add: Rule "Private repositories" with scenario for USPECS_GITHUB_TOKEN
- [x] update: [devops/dev/tests.feature](../../specs/devops/dev/tests.feature)
  - add: Rule "Test runner behavior" with scenario for skip-as-failure reporting

## Construction

- [x] update: [u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)
  - update: `cmd_action_umergepr` - after merge succeeds and pr_remote is "upstream", retry fetch+ff for up to 5 seconds until WCF is detected
- [x] update: [u/scripts/conf.sh](../../u/scripts/conf.sh)
  - add: `github_curl` helper using USPECS_GITHUB_TOKEN for authenticated requests
  - update: replace all `curl -fsSL` calls with `github_curl`
  - update: `download_archive` to use GitHub API tarball endpoint
- [x] update: [tests/e2e/conf-install.bats](../../../tests/e2e/conf-install.bats)
  - remove: all `trap EXIT` calls (causes bats silent failures on Windows)
  - rename: `make_git_tmpdir` -> `make_temp_repo`, `make_git_tmpdir_with_origin` -> `make_temp_repo_with_origin`
  - update: use `BATS_TEST_TMPDIR` for automatic cleanup instead of manual mktemp+trap
- [x] update: [tests/run-tests.py](../../../tests/run-tests.py)
  - add: `ere_escape` for ERE metacharacter escaping in bats -f filters
  - update: unified bash -c invocation across platforms (removed IS_WINDOWS branch)
  - add: `--print-output-on-failure --tap` flags to bats invocation
  - add: skip-as-failure reporting (skipped tests count as failures in summary and exit code)
- [x] update: [tests/sys/stubs/gh](../../../tests/sys/stubs/gh)
  - add: push merged state to upstream remote after merge (simulates GitHub merge on fork)
- [x] update: [tests/sys/uspecs.sh-prompt-umergepr.bats](../../../tests/sys/uspecs.sh-prompt-umergepr.bats)
  - add: test for "PR in OPEN state: upstream remote exists"
- [x] update: [AGENTS.md](../../../AGENTS.md), [CLAUDE.md](../../../CLAUDE.md)
  - add: "Never use trap in bats tests" guideline
