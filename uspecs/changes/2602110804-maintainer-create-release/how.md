# How: Maintainer creates release

## Approach

- Create bash script `u/scripts/release.sh` to handle release creation
  - Read current version from `version.txt` file
    - If file doesn't exist, initialize with `1.0.0-a.1`
  - Validate version format (semantic versioning)
  - Determine new version based on current version - get rid of pre-release identifier if exists
    - Example: 1.0.12-a.4 -> 1.0.12
  - Create annotated git tag with version
  - Push tag to origin
  - Create a version branch named {new-version}
  - On the new branch, bump minor version, reset patch to 0, and add pre-release identifier `a.0` for next development cycle
    - Example: 1.0.12-a.4 -> 1.1.0-a.0
  - Make a commit with the new version
    - Commit message: "Bump version to X.Y.Z-a.1 for next development cycle"
  - Create a pull request from the new branch to main with the same commit message
    - Use GitHub CLI (`gh pr create`) for PR creation
    - Require GitHub CLI to be installed and authenticated
- Add `version.txt` file at repository root to track current version
  - Format: X.Y.Z-a.N (semantic version with optional pre-release identifier)
  - Example: 1.0.0-a.1 or 1.0.12
  - Single source of truth for version number
- Follow existing script patterns from `u/scripts/uspecs.sh` and `u/scripts/update-from-home.sh`
  - Use `set -Eeuo pipefail` for error handling
  - Implement helper functions for validation
  - Provide clear error messages

References:

- [u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)
- [u/scripts/update-from-home.sh](../../u/scripts/update-from-home.sh)
- [u/scripts/update-from-home-pr.sh](../../u/scripts/update-from-home-pr.sh)
