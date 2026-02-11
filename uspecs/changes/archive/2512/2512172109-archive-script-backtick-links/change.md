# Change: Archive script should put all links into backticks

- archived_at: 2025-12-17T20:27:30Z
- registered_at: 2025-12-17T20:06:18Z
- change_id: 251217-archive-script-backtick-links
- baseline: 3a1e8dabba090cf78466b30059a1570881311099

## Problem

When changes are archived using the archive script, markdown links in the archived files remain as active links. Over time, these links can become broken or point to moved/renamed files, making archived documentation harder to understand and maintain.

## Proposal

Update the archive script (uspecs.sh changes archive command) to automatically convert all markdown links to backtick-wrapped text format when archiving a change. This preserves the link information as historical reference while clearly indicating they are no longer active links.

The conversion should:

- Process all markdown files in the change folder being archived
- Convert markdown links from `[text](url)` format to `[text](url)` format (wrapped in backticks)
- Skip links that are already wrapped in backticks to avoid double-wrapping
- Use sed for efficient batch processing

## Principles

- Active Change Folder is passed as argument to the archive script
- use sed for text processing, detect and convert markdown links
