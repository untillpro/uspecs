# Implementation plan

## Functional design

- [ ] update: [prod/prod--domain.md](../../specs/prod/prod--domain.md)
  - add: new concepts to mgmt context or domain-level Concepts section: Invocation Method (NLI, CB), NLI Types (nlia, nlic), CB Types, Version Types (Stable, Alpha)

- [ ] create: [prod/mgmt/install.feature](../../specs/prod/mgmt/install.feature)
  - add: Scenario for installing uspecs with --nlia or --nlic
  - add: Scenario for installing with --alpha flag
  - add: Scenario for installation failure (no git repo, already installed)

- [ ] create: [prod/mgmt/update.feature](../../specs/prod/mgmt/update.feature)
  - add: Scenario for updating alpha version (latest commit from main branch)
  - add: Scenario for updating stable version (latest minor version)
  - add: Scenario for no new version available (alpha and stable)
  - add: Scenario for update with --project-dir (second phase)

- [ ] create: [prod/mgmt/upgrade.feature](../../specs/prod/mgmt/upgrade.feature)
  - add: Scenario for upgrading to latest major version (stable only)
  - add: Scenario for upgrade failure on alpha version

- [ ] create: [prod/mgmt/invocation-type-mgmt.feature](../../specs/prod/mgmt/invocation-type-mgmt.feature)
  - add: Scenario for adding invocation type (--add nlia, --add nlic)
  - add: Scenario for removing invocation type (--remove)
  - add: Scenario for configuring multiple invocation types simultaneously