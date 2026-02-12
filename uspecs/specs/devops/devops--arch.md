# Domain architecture: devops

## Key components

- [release.sh: bash script](../../../scripts/release.sh)
  - Automates release creation workflow
  - Manages version tagging and branching

- [version.txt: text file](../../../version.txt)
  - Stores current version number
  - Single source of truth for version tracking

## Key data models

### Version format

- Semantic versioning: X.Y.Z-aN
  - X: major version
  - Y: minor version
  - Z: patch version
  - aN: pre-release identifier (optional, alpha build number)
- Examples: 1.0.0-a0 (development), 1.0.12 (release)

### Release workflow states

- Development: X.Y.Z-aN (pre-release identifier present)
- Release: X.Y.Z (pre-release identifier removed)
- Next development cycle: X.Y+1.0-a0 (minor bumped, patch reset, pre-release added)
