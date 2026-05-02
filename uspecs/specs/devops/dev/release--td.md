# Feature technical design: release

## Key components

- [release.yml: GitHub Action](../../../../.github/workflows/release.yml)
  - Manual trigger (workflow_dispatch) for release process
  - Executes release.sh script

- [release.sh: bash script](../../../../scripts/release.sh)
  - Automates two-phase release workflow
  - Phase 1: create git tag with release version
  - Phase 2: create version bump PR for next development cycle

- [version.txt: text file](../../../../version.txt)
  - Stores current version number
  - Single source of truth for version tracking

## Key flows

### Developer triggers release

```text
Developer -> release.yml (workflow_dispatch)
               |
               v
           release.sh
               |
               +-- reads version.txt (X.Y.Z-dev)
               +-- creates tag vX.Y.Z (version.txt set to X.Y.Z)
               +-- pushes tag to remote
               +-- creates PR "X.Y+1.0-dev" to main (version.txt set to X.Y+1.0-dev)
```

## Key data models

### Version transformation

- Given version X.Y.Z-dev:
  - Tag: vX.Y.Z (strip pre-release identifier, version.txt set to X.Y.Z)
  - PR: X.Y+1.0-dev (bump minor, reset patch, version.txt set to X.Y+1.0-dev)
