---
registered_at: 2026-02-11T08:05:13Z
change_id: 2602110804-maintainer-create-release
baseline: 9ae432bae072fc1cf1e83d90159d90a876ca47a6
archived_at: 2026-02-12T17:51:11Z
---

# Change request: Maintainer creates release

## Why

Enable maintainers to create releases by tagging the current version in the main branch, establishing a formal release process for version management.

## What

Maintainer can create a release:

- Read version from version.txt (format: X.Y.Z-aN)
- Create git tag vX.Y.Z (remove pre-release identifier)
- Create version branch "version X.Y.Z"
- Bump to next dev version X.Y+1.0-a0
- Create PR for version bump

Artifacts:

- scripts/release.sh - release automation script
- version.txt - version tracking file
- uspecs/specs/devops/dev/version-mgmt/release.feature - functional spec
- uspecs/specs/devops/devops--arch.md - architecture doc
