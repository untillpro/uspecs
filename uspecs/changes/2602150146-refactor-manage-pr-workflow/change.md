---
registered_at: 2026-02-15T01:46:55Z
change_id: 2602150146-refactor-manage-pr-workflow
baseline: 404b8ea20a16493d114b3b780961d8028e233166
---

# Change request: Refactor manage.sh to support PR workflows and improve version management

## Why

The manage.sh script needed better support for creating pull requests during install/update/upgrade operations, improved alpha version handling with commit timestamps, and a more robust architecture with separated PR logic and better error handling. The previous implementation had PR logic embedded in manage.sh and used separate update-from-home scripts that duplicated functionality.

## What

Enhanced manage.sh with PR workflow support and improved architecture:

- PR workflow integration
  - Add --pr flag support for install, update, and upgrade commands
  - Extract PR logic into separate _lib/pr.sh library script
  - Support both fork (upstream) and origin-only workflows
  - Automatic PR creation with branch management and cleanup

- Alpha version improvements
  - Include commit timestamps in version display
  - Format version strings for both display and git branch names
  - Add branch name sanitization for git compatibility
  - Store commit metadata in uspecs.yml for alpha versions

- Architecture improvements
  - Refactor install/update/upgrade to use unified cmd_apply function
  - Add show_operation_plan to display detailed operation information before execution
  - Improve temporary file and directory management with automatic cleanup
  - Better error handling and prerequisite validation

- Code cleanup
  - Remove deprecated update-from-home.sh and update-from-home-pr.sh scripts
  - Consolidate version resolution logic
  - Improve function organization and naming consistency
