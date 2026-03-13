# Implementation plan: Script creates change folder

## Construction

- [x] update: [u/scripts/uspecs.sh](../../../../u/scripts/uspecs.sh)
  - add: `get_project_dir` helper (3 levels up from scripts/ to project root)
  - add: `cmd_change_new` function: accepts `<change-name> [--issue-url <url>]`, generates ymdHM timestamp, creates Change Folder, creates change.md with frontmatter, prints `Created change folder: <absolute-path>`
  - add: `new` subcommand dispatch in `change` case
  - remove: `cmd_change_frontmatter` function and its `frontmatter` dispatch entry - no longer needed once `change new` owns folder and frontmatter creation
  - update: header comment to replace `change frontmatter` usage with `change new`

- [x] update: [u/actn-uchange.md](../../../../u/actn-uchange.md)
  - update: Flow section - replace folder-creation step and `change frontmatter` call with single `change new` call; Agent parses returned path
  - keep: Agent writes Change File body content to change.md after the script creates the file with frontmatter
  - keep: Agent handles all other artifacts like issue.md, git branch creation etc.

- [x] update: [u/conf.md](../../../../u/conf.md)
  - remove: ymdHM format specification (lines 13-20) - folder naming is now owned by the script
