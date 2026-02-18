# Implementation plan: Rename mgmt to conf, invocation type to invocation method

## Functional design

- [x] update: [prod--domain.md](../../specs/prod/prod--domain.md)
  - rename: `mgmt` context name, description, and context map entry to `conf`
  - rename: "Invocation Type" concept to "Invocation Method"

- [x] rename: [mgmt/invocation-type-mgmt.feature](../../specs/prod/mgmt/invocation-type-mgmt.feature)
  - rename: to conf/invocation-method-conf.feature
  - update: feature title "Configure invocation types" to "Configure invocation methods"
  - update: `manage.sh it` -> `conf.sh it` in scenario steps
  - update: `invocation_types` -> `invocation_methods` in config file reference

- [x] move: [mgmt/install.feature](../../specs/prod/mgmt/install.feature)
  - move: to conf/install.feature
  - update: "invocation type" -> "invocation method"

- [x] move: [mgmt/update.feature](../../specs/prod/mgmt/update.feature)
  - move: to conf/update.feature
  - update: `manage.sh` -> `conf.sh` in scenario steps

- [x] move: [mgmt/upgrade.feature](../../specs/prod/mgmt/upgrade.feature)
  - move: to conf/upgrade.feature
  - update: `manage.sh` -> `conf.sh` in scenario steps

- [x] rename: [mgmt/mgmt--arch.md](../../specs/prod/mgmt/mgmt--arch.md)
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

- [x] rename: [u/scripts/manage.sh](../../u/scripts/manage.sh)
  - rename: to u/scripts/conf.sh
  - update: `manage.sh` -> `conf.sh` in header, usage, error messages, and internal script path calls
  - update: "invocation type/types" -> "invocation method/methods" in user messages
  - update: `invocation_types` -> `invocation_methods` in YAML key reads and writes
