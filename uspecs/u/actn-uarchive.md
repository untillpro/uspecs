# Action: Archive change

## Overview

Archive a completed change request folder.

## Instructions

Rules:

- Always read `uspecs/u/concepts.md` and `uspecs/u/conf.md` before proceeding and follow the definitions and rules defined there

Parameters:

- Input
  - Active Change Folder path
  - -d flag (optional): after archiving, commit and push staged changes and remove associated branch and refs
- Output
  - Folder moved to `$changes_folder/archive`
  - If -d flag: git commit and push with message `archive <folder-from> <folder-to>`, branch and refs removed

Flow:

- Identify Active Change Folder to archive, if unclear, ask user to specify folder name
- Execute `bash uspecs/u/scripts/uspecs.sh change archive <change-folder-name>`
  - If -d flag provided, add `-d` parameter: `bash uspecs/u/scripts/uspecs.sh change archive <change-folder-name> -d`
  - Example: `bash uspecs/u/scripts/uspecs.sh change archive 2602211523-check-cmd-availability -d`
- Analyze output, show to user and stop
