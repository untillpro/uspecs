# Implementation plan: Exit with message when install --override versions match

## Construction

- [x] update: [specs/prod/conf/install.feature](../../../../specs/prod/conf/install.feature)
  - update: "Install with --override" scenario - add step that versions are compared and script exits with message when equal, suggesting to remove uspecs.yml
- [x] update: [u/scripts/conf.sh](../../../../u/scripts/conf.sh)
  - update: `cmd_apply` - when override is true and metadata_file exists, load config and compare versions (by commit for alpha, by version for stable); if equal, echo message suggesting to remove uspecs.yml and return 0
- [x] update: [tests/e2e/conf-install.bats](../../../../../tests/e2e/conf-install.bats)
  - add: test that install --override with same version exits successfully with suggestion message
  - update: existing "Install with --override succeeds when already installed" test - ensure first and second installs use different versions or verify it still works when versions differ
