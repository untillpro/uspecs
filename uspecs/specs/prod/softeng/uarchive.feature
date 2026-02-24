Feature: Archive change request
  Engineer archives a completed change request

  Background:
    Given Active Change Folder is unambiguous

  Scenario: Archive change request
    When Engineer invokes uarchive action
    Then Active Change Folder is moved to changes archive

  Scenario: Archive change request on PR branch
    Given current branch ends with "--pr"
    When Engineer invokes uarchive action
    Then AI Agent asks Engineer to confirm git cleanup
    And on confirmation Active Change Folder is moved to changes archive
    And on confirmation git commit is made and pushed with message "archive <folder-from> <folder-to>"
    And on confirmation associated branch and its refs are removed
    And on rejection Active Change Folder is moved to changes archive without git cleanup
