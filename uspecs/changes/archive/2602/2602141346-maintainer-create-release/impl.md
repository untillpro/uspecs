# Implementation plan: Developer creates release

## Functional design

- [x] update: [dev/release.feature](../../../../specs/devops/dev/release.feature)
  - add: Developer triggers release via GitHub Action scenario

## Technical design

- [x] update: [devops/devops--arch.md](../../../../specs/devops/devops--arch.md)
  - add: GitHub Action workflow component for manual release triggering
  - add: release.sh component description

- [x] create: [dev/release--td.md](../../../../specs/devops/dev/release--td.md)
  - add: Release workflow component interaction flow
  - add: Version transformation data model

## Construction

- [x] create: [version.txt](../../../../../version.txt)
  - add: Initial version number (1.0.0-a0)

- [x] update: [scripts/release.sh](../../../../../scripts/release.sh)
  - update: Release workflow to two-phase flow (create tag, then create version bump PR)

- [x] create: [.github/workflows/release.yml](../../../../../.github/workflows/release.yml)
  - add: GitHub Action workflow with workflow_dispatch trigger
  - add: Job to execute release.sh script
  - add: Required permissions for creating tags and PRs
