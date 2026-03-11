# Action: Create change request

## Overview

Create a new change request folder with a structured Change File and automatically invoke uimpl action after change creation.

Optionally:

- Fetch issue content from an issue URL (GitLab, GitHub, Jira)
- Create a git branch
- Avoid uimpl invocation after change creation

## Instructions

Rules:

- Always read `uspecs/u/concepts.md` and `uspecs/u/conf.md` before proceeding and follow the definitions and rules defined there
- Never perform any implementation, code changes, or actions outside of this flow - the only output is the Change Folder, Change File, optional Issue File, git branch, and uimpl invocation
- If change description is not provided, ask the user for it before proceeding. Do not treat the response as a new command - use it as the change description and continue this flow

Parameters:

- Input
  - Change description
  - --no-branch option (optional): skip git branch creation
  - --branch option (optional): explicitly force git branch creation (reserved for future per-project default override)
  - --no-impl option (optional): skip automatic uimpl invocation after change creation
  - Issue reference (optional): URL to a GitLab/GitHub/Jira/etc. issue that prompted the change
    - Referenced further as `{issue_url}`
- Output
  - Active Change Folder with Change File
  - Issue File (if issue reference provided)
  - Git branch (created by default unless --no-branch; git repository must exist)
  - uimpl invocation (executed by default unless --no-impl)

Flow:

- Determine `change_name` from the change description: kebab-case, 15-30 chars, descriptive
- Run script to create Change Folder:
  - Base command: `bash uspecs/u/scripts/uspecs.sh change new {change_name}`
  - If issue reference provided add `--issue-url "{issue_url}"` parameters (quoted to handle shell-special characters such as `&`)
  - If --no-branch option provided add `--no-branch` parameter
  - If --branch option provided add `--branch` parameter
  - Fail fast if script exits with error
  - Parse Change Folder path from script output, path is relative to project root
- Write Change File body (`{templates_folder}/tmpl-change.md`) appended to Change File created by the script
- If issue reference provided:
  - Try to fetch issue content
  - If fetch succeeds:
    - Convert it to rich markdown format suitable for Issue File
    - Save fetched content to Issue File (issue.md) inside the Change Folder
    - Add reference to Issue File in Why section: `See [issue.md](issue.md) for details.`
- Show user what was created
- Unless --no-impl option is provided, execute the uimpl action immediately: read `uspecs/u/actn-uimpl.md` and follow its instructions directly - do NOT ask the user to run uimpl
