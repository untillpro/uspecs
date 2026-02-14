# Implementation plan

## Functional design

- [x] update: [prod/prod--domain.md](../../specs/prod/prod--domain.md)
  - add: Invocation Method, Invocation Type, and Version Type concepts to domain-level Concepts section
  - update: mgmt context description to "Manage the System lifecycle - install, update, upgrade and maintain uspecs per project"
  - update: context map from "conf -> |parameters| softeng" to "mgmt -> |working uspecs| softeng"

- [x] create: [prod/mgmt/install.feature](../../specs/prod/mgmt/install.feature)
  - add: Scenario Outline "Install stable version" with README.md precondition and file creation
  - add: Scenario "Install alpha version" with flag inheritance from stable install
  - add: Rule "Edge cases" with Scenario Outline "Installation failure"

- [x] create: [prod/mgmt/update.feature](../../specs/prod/mgmt/update.feature)
  - add: Scenario Outline "Update when new version is available" for alpha and stable
  - add: Scenario Outline "No new version available" with upgrade hint for stable major version

- [x] create: [prod/mgmt/upgrade.feature](../../specs/prod/mgmt/upgrade.feature)
  - add: Scenario "Upgrade stable version"
  - add: Rule "Edge cases" with Scenario "Upgrade fails on alpha" with exact error message

- [x] create: [prod/mgmt/invocation-type-mgmt.feature](../../specs/prod/mgmt/invocation-type-mgmt.feature)
  - add: Scenario Outline "Manage invocation type" with file creation and add/remove operations

- [x] update: [u/ex-domain-prod.md](../../u/ex-domain-prod.md)
  - update: conf context renamed to mgmt with updated description and relationships

## Technical design

- [x] create: [prod/mgmt/mgmt--arch.md](../../specs/prod/mgmt/mgmt--arch.md)
  - add: Key components (manage.sh script, uspecs.yml config file, GitHub repository, agent config files)
  - add: Key flows in ASCII text format (version detection and download, local installation, config file management)
  - add: Key data models (config file structure for stable and alpha versions)
