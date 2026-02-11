# How: Maintainer creates release

## Approach

- Create bash script `u/scripts/release.sh` to handle release creation
  - Read current version from `version.txt` file (create if not exists)
  - Validate version format (semantic versioning)
  - Create annotated git tag with version
  - Push tag to origin
  - Bump minor version, reset patch to 0, and add pre-release identifier `a.1` for next development cycle
    - Example: 1.0.12-* -> 1.1.0-a.1
  - Make a commit with the new version
    - Commit message: "Bump version to X.Y.Z-a.1 for next development cycle"
- Add `version.txt` file at repository root to track current version
  - Format: X.Y.Z (1.0.0-a.1)
  - Single source of truth for version number
- Follow existing script patterns from `u/scripts/uspecs.sh` and `u/scripts/update-from-home.sh`
  - Use `set -Eeuo pipefail` for error handling
  - Implement helper functions for validation
  - Provide clear error messages

References:

- [u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)
- [u/scripts/update-from-home.sh](../../u/scripts/update-from-home.sh)
- [u/scripts/update-from-home-pr.sh](../../u/scripts/update-from-home-pr.sh)
