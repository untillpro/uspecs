# Subsystem architecture: Release management

## Components

### Branches

Mainline version branches:

- `main`: development branch
  - version: `Xm.Ym.0-dev`
- `rc-Xm`: pre-release branch for current major version
  - version: Xm.(Ym-1).Zrc-rc
- `rc-Xm-patch`: patch branch for current pre-release version
  - version: Xm.(Ym-1).(Zrc+1)-rc
- `release-Xm`: release branch for the current release version
  - version: Xm.(Ym-1).(Zr) | Xm.(Ym-2).(Zr)
- `release-Xm-patch`: patch branch for the current release version
  - version: Xm.(Ym-1).(Zr+1) | Xm.(Ym-2).(Zr+1)

Mainline pull request branches:

- `main-Xm-changelog`: created by the `uchangelog` workflow
  - target branch: `main`
  - Updates CHANGELOG.md
  - Merging this PR triggers
    - Force merging `main` to `rc-Xm` with version `Xm.Ym.0-rc0`
    - Bumping version in development branch to `X.(Y+1).0-dev`
    - Removing `main-Xm-changelog` branch
- `rc-Xm-changelog`: created by the `uchangelog` workflow
  - target branch: `rc-Xm`
  - Updates CHANGELOG.md
  - Merging this PR to the rc branch with version `A.B.C-rc0` triggers
    - Force merging `rc-Xm` to `release-Xm` with version `A.B.0`
    - Bumping version in rc branch to `A.B.C-rc1`
    - Removing `rc-Xm-changelog` branch
- `release-Xm-changelog`: created by the `uchangelog` workflow
  - target branch: `release-Xm`
  - Updates CHANGELOG.md
  - Merging this PR to the release branch with version `A.B.C` triggers
    - Bumping version in release branch to `A.B.(C+1)`
    - Removing `release-Xm-changelog` branch

Maintenance version branches and PRs (multiple versions may be maintained in parallel):

- `rc-Xl`: pre-release branch(es) for previous major version(s)
  - version: Xl.Yl.Zl-rc
- `rc-Xl-patch`: patch branch(es) for previous major version(s)
  - version: Xl.Yl.(Zl+1)-rc
- `rc-Xl-changelog`
- ...

### Workflows

- `changelogs`: workflow that creates `rc-X-changelog`
