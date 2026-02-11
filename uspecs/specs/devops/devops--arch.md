# Domain architecture: devops

## Key components

- [release.sh: bash script](../../../u/scripts/release.sh)
  - Automates release creation workflow
  - Manages version tagging and branching

- [version.txt: text file](../../../version.txt)
  - Stores current version number
  - Single source of truth for version tracking

## Key data models

**Version format:**

- Semantic versioning: X.Y.Z-a.N
  - X: major version
  - Y: minor version
  - Z: patch version
  - a.N: pre-release identifier (optional, alpha build number)
- Examples: 1.0.0-a.1 (development), 1.0.12 (release)

**Release workflow states:**

- Development: X.Y.Z-a.N (pre-release identifier present)
- Release: X.Y.Z (pre-release identifier removed)
- Next development cycle: X.Y+1.0-a.1 (minor bumped, patch reset, pre-release added)
