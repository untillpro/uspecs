# Implementation plan

## Construction

- [x] create: [uspecs/u/scripts/_lib/pr.sh](../../../../../uspecs/u/scripts/_lib/pr.sh)
  - Add info command to output PR configuration (pr_remote, main_branch)
  - Add prbranch command to create branch from remote default branch
  - Add pr command to commit, push, and create pull request
  - Support both upstream (fork) and origin-only workflows
  - Handle branch cleanup and switching after PR creation
  - Output PR details (URL, branch, base) to stderr for caller parsing

- [x] update: [uspecs/u/scripts/manage.sh](../../../../../uspecs/u/scripts/manage.sh)
  - Add --pr flag support to install, update, and upgrade commands
  - Add check_pr_prerequisites function to validate git, gh CLI, and working directory
  - Add format_version_string function to display version with commit timestamp
  - Add format_version_string_branch function for git-safe branch names
  - Add sanitize_branch_name function to ensure valid git branch names
  - Add show_operation_plan function to display detailed operation information
  - Add confirm_action function with interactive and non-interactive modes
  - Refactor cmd_install to download and invoke target version's cmd_apply
  - Add cmd_update_or_upgrade to handle both update and upgrade commands
  - Add cmd_apply as unified handler for install/update/upgrade operations
  - Add resolve_update_version function to determine update target version
  - Add resolve_upgrade_version function to determine upgrade target version
  - Improve get_latest_commit_info to return both commit hash and timestamp
  - Add get_alpha_version function to fetch alpha version from version.txt
  - Add is_alpha_version function to check if version is alpha
  - Improve temporary file/directory management with create_temp_file and create_temp_dir
  - Add cleanup_temp function with trap for automatic cleanup
  - Update write_metadata to preserve installed_at timestamp
  - Integrate pr.sh for PR branch creation and submission
  - Update cmd_it to use new temporary file management

- [x] delete: [uspecs/u/scripts/update-from-home-pr.sh](../../../../../uspecs/u/scripts/update-from-home-pr.sh)
  - Functionality replaced by --pr flag in manage.sh

- [x] delete: [uspecs/u/scripts/update-from-home.sh](../../../../../uspecs/u/scripts/update-from-home.sh)
  - Functionality replaced by update command in manage.sh
