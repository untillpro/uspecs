Feature: Archive change request
  Engineer archives a completed change request

  Scenario Outline: Archive change request
    Given <condition>
    When Engineer invokes uarchive action
    Then <outcome>
    Examples:
      | condition                              | outcome                                                     |
      | Active Change Folder is unambiguous    | Active Change Folder is moved to changes archive            |
      | Active Change Folder name is ambiguous | AI Agent asks Engineer to specify Active Change Folder name |

  Scenario Outline: Archive change request with -d flag
    Given Active Change Folder is unambiguous
    And <condition>
    When Engineer invokes uarchive -d action
    Then Active Change Folder is moved to changes archive
    And git commit is made and pushed with message "archive <folder-from> <folder-to>"
    And <outcome>
    Examples:
      | condition                    | outcome                                    |
      | associated branch exists     | associated branch and its refs are removed |
      | associated branch is missing | AI Agent warns Engineer and continues      |

