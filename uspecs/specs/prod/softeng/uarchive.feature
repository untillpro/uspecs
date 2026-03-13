Feature: Archive change request
  Engineer archives a completed change request


  Scenario: Archive change request
    Given Active Change Folder is unambiguous
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
    And on option 1 git commit is made with message "archive <folder-from> to <folder-to>"
    And on option 1 commit is pushed if remote branch exists
    And on option 1 associated branch and its refs are removed
    And on option 1 Engineer is switched to default branch
    And on option 1 local default branch is fast-forwarded to pr_remote/default_branch
    And on option 1 deleted branch hash is reported to Engineer together with instructions on how to restore the branch if needed
    And on option 2 Active Change Folder is moved to changes archive without git cleanup
    And on option 3 no action is taken

  Scenario: Archive all modified change folders
    When Engineer invokes uarchive action with --all option
    Then all change folders that have modifications vs pr_remote/default_branch are archived
    And count of archived, unchanged, and failed folders is reported

  Rule: Edge cases

    Scenario: Archive on PR branch when remote branch no longer exists
      Given current branch ends with "--pr"
      And remote branch no longer exists on origin
      When Engineer invokes uarchive action and selects git cleanup option
      Then git commit is made without pushing
      And local branch and tracking refs are removed

    Scenario: Archive fails when default branch cannot be fast-forwarded
      Given current branch ends with "--pr"
      And local default branch has diverged from pr_remote/default_branch
      When Engineer invokes uarchive action and selects git cleanup option
      Then action fails with error indicating default branch cannot be fast-forwarded
