# Implementation plan: Rename mgmt to conf, invocation type to invocation method

## Functional design

- [x] update: [prod--domain.md](../../specs/prod/prod--domain.md)
  - rename: `mgmt` context name, description, and context map entry to `conf`
  - rename: "Invocation Type" concept to "Invocation Method"

- [x] rename: [mgmt/invocation-type-conf.feature](../../specs/prod/conf/invocation-method-conf.feature)
  - rename: to conf/invocation-method-conf.feature
  - update: feature title "Configure invocation types" to "Configure invocation methods"
  - update: `manage.sh it` -> `conf.sh it` in scenario steps
  - update: `invocation_types` -> `invocation_methods` in config file reference

- [x] move: [mgmt/install.feature](../../specs/prod/conf/install.feature)
  - move: to conf/install.feature
  - update: "invocation type" -> "invocation method"

- [x] move: [mgmt/update.feature](../../specs/prod/conf/update.feature)
  - move: to conf/update.feature
  - update: `manage.sh` -> `conf.sh` in scenario steps

- [x] move: [mgmt/upgrade.feature](../../specs/prod/conf/upgrade.feature)
  - move: to conf/upgrade.feature
  - update: `manage.sh` -> `conf.sh` in scenario steps

- [x] rename: [mgmt/mgmt--arch.md](../../specs/prod/conf/conf--arch.md)
  - rename: to conf/conf--arch.md
  - update: `prod/mgmt` -> `prod/conf` in header
  - update: `manage.sh` -> `conf.sh` throughout
  - update: "invocation type/types" -> "invocation method/methods" throughout
  - update: `invocation_types` -> `invocation_methods` throughout

- [x] update: [README.md](../../../README.md)
  - update: `manage.sh` -> `conf.sh` in all install/update/upgrade/it commands
  - update: "Configure Invocation Types" section header and description

- [x] update: [u/ex-domain-prod.md](../../u/ex-domain-prod.md)
  - rename: `### mgmt` -> `### conf`
  - update: context description, relationships, and context map entry

- [x] rename: [u/scripts/conf.sh](../../u/scripts/conf.sh)
  - rename: to u/scripts/conf.sh
  - update: `manage.sh` -> `conf.sh` in header, usage, error messages, and internal script path calls
  - update: "invocation type/types" -> "invocation method/methods" in user messages
  - update: `invocation_types` -> `invocation_methods` in YAML key reads and writes
  - fix: `show_operation_plan` - corrected section order and labels: "Incoming version:" (target) shown first, "Existing version:" (current + project details) shown second; skipped for install
  - fix: `get_latest_minor_tag` - added `|| true` pipefail guard and `$current_version` fallback when no tag found

- [x] update: [u/scripts/conf.sh](../../u/scripts/conf.sh)
  - remove: `check_pr_prerequisites` function and all its call sites
  - add: `pr.sh ffdefault` call in `cmd_apply` before `prbranch` when `--pr`
  - add: version match check in `cmd_apply` for update/upgrade; `--current-version` required check

- [x] update: [u/scripts/_lib/pr.sh](../../u/scripts/_lib/pr.sh)
  - add: `gh` CLI check to `check_prerequisites`
  - add: `cmd_ffdefault` command to fetch and fast-forward default branch
  - rename: `main_branch_name` -> `default_branch_name` throughout
  - update: dispatch and usage to include `ffdefault`
