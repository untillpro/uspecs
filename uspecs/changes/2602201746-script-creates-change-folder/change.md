---
registered_at: 2026-02-20T17:46:41Z
change_id: 2602201746-script-creates-change-folder
baseline: 76f2577389bf486bfed25abe971afebf30de80d1
---

# Change request: Script creates change folder

## Why

Currently the Agent generates the timestamp, creates the Change Folder, and creates change.md with body content before calling the script to add frontmatter. This splits responsibility awkwardly: the Agent must know the folder naming convention and produce a correctly named folder before the script can validate and decorate it.

## What

Introduce a new `change new` subcommand to `uspecs.sh` that owns folder creation:

- Add `uspecs change new <change-name> [--issue-url <url>]` to `uspecs.sh`:
  - Generates the ymdHM timestamp prefix (UTC)
  - Creates the Change Folder under `$project_dir/uspecs/changes/`
  - Creates `change.md` with frontmatter only (`registered_at`, `change_id`, `baseline`, `issue_url` if provided)
  - Prints `Created change folder: <absolute-path>` for the Agent to parse
- Update `actn-uchange.md` Flow:
  - Remove the separate folder-creation and `change frontmatter` steps
  - Agent calls `change new`, parses the returned path, then writes the Change File body content to change.md
  - Issue File creation and git branch steps remain unchanged
- Update `conf.md`:
  - Remove the ymdHM format specification - folder naming is now owned by the script, not the Agent
