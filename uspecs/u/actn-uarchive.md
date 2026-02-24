# Action: Archive change

## Overview

Archive a completed change request folder.

## Instructions

Rules:

- Always read `uspecs/u/concepts.md` and `uspecs/u/conf.md` before proceeding and follow the definitions and rules defined there

Parameters:

- Input
  - Active Change Folder path
- Output
  - Folder moved to `$changes_folder/archive`
  - If on PR branch and Engineer confirms: git commit and push with message, branch and refs removed

Flow:

- Identify Active Change Folder to archive, if unclear, ask Engineer to specify folder name
- Run `bash uspecs/u/scripts/uspecs.sh status ispr`
  - If output is `yes`: warn Engineer that current branch ends with `--pr` and ask to confirm git cleanup (commit, push, delete branch and refs)
    - On confirmation: `bash uspecs/u/scripts/uspecs.sh change archive <change-folder-name> -d`
    - On rejection: `bash uspecs/u/scripts/uspecs.sh change archive <change-folder-name>`
  - Otherwise: `bash uspecs/u/scripts/uspecs.sh change archive <change-folder-name>`
- Analyze output, show to Engineer and stop
