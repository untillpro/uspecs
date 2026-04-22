Feature: Archive change request
  Engineer archives a completed change request


  Scenario: Archive change request
    Given Active Change Folder is unambiguous
    When Engineer invokes uarchive action
    Then Active Change Folder is moved to changes archive

  Scenario: Archive all modified change folders
    When Engineer invokes uarchive action with --all option
    Then all change folders that have modifications vs pr_remote/default_branch are archived
    And count of archived, unchanged, and failed folders is reported

  Scenario: Multiple Active Change Folders
    Given there are multiple Active Change Folders
    When Engineer invokes uarchive action
    Then AI Agent asks Engineer to select which folder to archive
