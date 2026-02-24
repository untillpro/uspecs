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
    Then AI Agent presents Engineer with the following options:
      | # | action                                                                            |
      | 1 | Archive + git cleanup (commit, push, delete local branch and remote tracking ref) |
      | 2 | Archive only (no git operations)                                                  |
      | 3 | Cancel                                                                            |
    And on option 1 Active Change Folder is moved to changes archive
    And on option 1 git commit is made and pushed with message "archive <folder-from> to <folder-to>"
    And on option 1 associated branch and its refs are removed
    And on option 2 Active Change Folder is moved to changes archive without git cleanup
    And on option 3 no action is taken
