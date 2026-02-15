# Implementation plan: Add --pr flag to update and upgrade commands

## Functional design

- [x] update: [prod/mgmt/update.feature](../../../../specs/prod/mgmt/update.feature)
  - update: Scenario Outline "Update when new version is available" to add pr_flag and pr_action parameters
  - add: Examples for --pr flag with alpha and stable versions

- [x] update: [prod/mgmt/upgrade.feature](../../../../specs/prod/mgmt/upgrade.feature)
  - update: Scenario "Upgrade stable version" to Scenario Outline with pr_flag and pr_action parameters
  - add: Examples for --pr flag

## Construction

- [x] update: [uspecs/u/scripts/manage.sh](../../../../../uspecs/u/scripts/manage.sh)
  - add: Helper function format_version_string to format version string for alpha and stable versions
  - add: Helper function validate_pr_prerequisites to check GitHub CLI, origin remote, and clean working directory
  - add: Helper function determine_pr_remote to select upstream or origin for PR target
  - add: Helper function create_pr_workflow to handle branch creation, commit, push, and PR creation
  - update: cmd_update function to accept --pr flag and call PR workflow if provided
  - update: cmd_upgrade function to accept --pr flag and call PR workflow if provided

## Quick start

Update to latest version and create PR:

```sh
uspecs/u/scripts/manage.sh update --pr
```

Upgrade to latest major version and create PR:

```sh
uspecs/u/scripts/manage.sh upgrade --pr
```

The script will:

- Switch to main branch
- Update main from upstream (or origin)
- Push updated main to origin
- Perform update/upgrade
- Create branch with version-based naming
- Commit and push changes
- Create PR to upstream (or origin)
- Clean up local branch
