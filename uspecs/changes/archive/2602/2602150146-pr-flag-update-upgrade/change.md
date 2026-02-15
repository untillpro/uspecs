---
registered_at: 2026-02-15T01:22:41Z
change_id: 2602150122-pr-flag-update-upgrade
baseline: ced8af554a32ffa6c12d65a894a2e20a2e37402a
archived_at: 2026-02-15T01:46:23Z
---

# Change request: Add --pr flag to update and upgrade commands

## Why

The update-from-home-pr.sh script demonstrates a useful workflow for creating PRs after updating uspecs. This same workflow should be available for the standard update and upgrade commands in manage.sh to streamline the process of proposing uspecs updates via pull requests.

## What

Add --pr flag support to cmd_update and cmd_upgrade functions in manage.sh:

- cmd_update function accepts optional --pr flag
- cmd_upgrade function accepts optional --pr flag
- When --pr flag is provided:
  - Switches to main branch
  - Updates main from PR Remote with rebase
  - Pushes updated main to Origin Remote
  - Executes perform_update or standard upgrade logic
  - Reads version info from uspecs/u/uspecs.yml metadata file
  - Formats version string:
    - For alpha: "alpha-{timestamp}-{commit-hash-short}" where timestamp is YYYYMMDDHHmm (without seconds) and commit-hash-short is first 8 characters
    - For stable: "{version}" (e.g., "2.0.0")
  - Creates Git Branch with naming pattern: update-uspecs-{version-string} for update, upgrade-uspecs-{version-string} for upgrade
  - If no changes detected (git status --porcelain is empty):
    - Deletes Git Branch
    - Reports "No updates were needed" to Engineer
    - Exits successfully
  - If changes detected:
    - Commits changes with message: "Update uspecs to {version}" or "Upgrade uspecs to {version}"
    - Pushes Git Branch to Origin Remote
    - Creates Pull Request to PR Remote using GitHub CLI (gh pr create)
    - PR title: "Update uspecs to {version}" or "Upgrade uspecs to {version}"
    - PR body includes version info
    - Deletes local Git Branch (remote branch remains for PR)
    - Reports success to Engineer
- When --pr flag is not provided, behavior remains unchanged (local update/upgrade only)
- Prerequisites validation before PR workflow:
  - GitHub CLI (gh) must be installed
  - Origin Remote must exist
  - PR Remote determination: Upstream Remote if exists, otherwise Origin Remote
  - Working directory must be clean (no uncommitted changes)
- Error handling:
  - If prerequisites not met, report error and exit
  - If version info cannot be read from uspecs/u/uspecs.yml, report error and exit

## Examples

### Example 1: Update with --pr flag (alpha version)

Engineer runs:

```sh
uspecs/u/scripts/manage.sh update --pr
```

Workflow:

- Switches to main branch
- Updates main from upstream (or origin if no upstream)
- Pushes updated main to origin
- Performs update to latest alpha commit
- Reads version from uspecs/u/uspecs.yml: "alpha"
- Reads commit from uspecs/u/uspecs.yml: "967257e2d86e4520b48e69d6300c603db359689b"
- Reads commit_timestamp from uspecs/u/uspecs.yml: "2026-02-14T16:00:00Z"
- Formats version string: "alpha-202602141600-967257e2" (timestamp without seconds, first 8 chars of commit)
- Creates branch: update-uspecs-alpha-202602141600-967257e2
- Commits with message: "Update uspecs to alpha-202602141600-967257e2"
- Pushes branch to origin
- Creates PR to upstream with title: "Update uspecs to alpha-202602141600-967257e2"
- Deletes local branch
- Reports success

### Example 2: Upgrade with --pr flag (stable version)

Engineer runs:

```sh
uspecs/u/scripts/manage.sh upgrade --pr
```

Workflow:

- Current version in uspecs/u/uspecs.yml: "1.2.3"
- Latest major version available: "2.0.0"
- Switches to main branch
- Updates main from upstream (or origin if no upstream)
- Pushes updated main to origin
- Performs upgrade to version 2.0.0
- Creates branch: upgrade-uspecs-2.0.0
- Commits with message: "Upgrade uspecs to 2.0.0"
- Pushes branch to origin
- Creates PR to upstream with title: "Upgrade uspecs to 2.0.0"
- PR body:
  ```text
  Upgrade uspecs to version 2.0.0

  Previous version: 1.2.3
  New version: 2.0.0
  ```
- Deletes local branch
- Reports success

## Definitions

- Origin Remote: git remote named "origin"
- Upstream Remote: git remote named "upstream" (optional)
- PR Remote: Upstream Remote if exists, otherwise Origin Remote
- Git Branch: git branch created for PR workflow
- Engineer: human user running the command
- GitHub CLI: gh command-line tool
