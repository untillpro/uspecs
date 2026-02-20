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
  - Folder moved to `$changes_folder/archive/yymm/` with archived_at metadata (if all items are checked or cancelled)

Flow:

- Identify Active Change Folder to archive, if unclear, ask user to specify folder name
- Execute `bash uspecs/u/scripts/uspecs.sh change archive <absolute-path-to-change-folder>`
- Analyze output, show to user and STOP

## Scenarios

```gherkin
Feature: Archive change request
  Engineer archives a completed change request

  Scenario Outline: Archive change request
    Given <condition>
    When Engineer asks AI Agent to archive change request
    Then <outcome>
    Examples:
      | condition                              | outcome                                                     |
      | Active Change Folder is unambiguous    | Active Change Folder is moved to changes archive            |
      | Active Change Folder name is ambiguous | AI Agent asks Engineer to specify Active Change Folder name |
```
