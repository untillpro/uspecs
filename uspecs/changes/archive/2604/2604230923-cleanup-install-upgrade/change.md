---
registered_at: 2026-04-23T08:43:50Z
change_id: 2604230843-cleanup-install-upgrade
baseline: 799ffb486bc59c19a3b9b13d247c2bbc8b6e80d5
archived_at: 2026-04-23T09:23:17Z
---

# Change request: Remove install/update/upgrade/im feature and its specifications

## Why

The install/update/upgrade/im feature implemented in `bin/conf.sh` no longer works. Keeping the broken code, its specifications, and tests adds maintenance overhead and causes confusion.

## What

Remove the uspecs self-install/update/upgrade and invocation-method-configuration feature along with all its specifications, tests, and user-facing documentation. Retain the `conf` context entry in the prod domain as a placeholder for future lifecycle management, and keep shared code that is still used elsewhere.

Summary of removals:

- `bin/conf.sh` (all commands: `install`, `update`, `upgrade`, `apply`, `im`)
- Feature and architecture specifications under `uspecs/specs/prod/conf/`
- Tests targeting the removed feature
- README sections describing install/update/upgrade/invocation-method configuration

Summary of retentions:

- `conf` context entry in `uspecs/specs/prod/domain.md`
- `bin/_lib/git.sh` and `bin/_lib/utils.sh` (used by `bin/softeng.sh`)
- `version.txt` at the repository root

## Construction

- [x] delete: `[bin/conf.sh](../../../../../bin/conf.sh)`
- [x] delete: `[uspecs/specs/prod/conf/arch.md](../../../../specs/prod/conf/arch.md)`
- [x] delete: `[uspecs/specs/prod/conf/install.feature](../../../../specs/prod/conf/install.feature)`
- [x] delete: `[uspecs/specs/prod/conf/update.feature](../../../../specs/prod/conf/update.feature)`
- [x] delete: `[uspecs/specs/prod/conf/upgrade.feature](../../../../specs/prod/conf/upgrade.feature)`
- [x] delete: `[uspecs/specs/prod/conf/invocation-method-conf.feature](../../../../specs/prod/conf/invocation-method-conf.feature)`
- [x] delete: `[tests/e2e/conf-install.bats](../../../../../tests/e2e/conf-install.bats)`
- [x] delete: `[tests/sys/conf.sh-apply.bats](../../../../../tests/sys/conf.sh-apply.bats)`

- [x] update: [README.md](../../../../../README.md)
  - remove: top-level install block (curl-pipe commands for `--nlia`, `--nlic`, `--alpha`, combined) including the `<details>` variants
  - remove: `### Update`, `### Upgrade`, and `### Configure invocation methods` sections
  - result: file contains only the `# uspecs` title
