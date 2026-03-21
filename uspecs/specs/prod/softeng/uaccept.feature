Feature: Accept pull request
  Engineer asks AI Agent to accept a PR associated with the current branch

  Scenario: PR not found
    Given no open PR exists for the current branch
    When Engineer invokes uaccept action
    Then message "No open PR found for the current branch" is displayed

  Scenario: PR in OPEN state
    Given PR associated with the current branch is in OPEN state
    When Engineer invokes uaccept action
    # Squash and delete local and remote branches
    Then Attempt to merge PR is made with -s -d options

  Scenario: PR in OPEN state: Attempt to merge PR fails
    Given Attempt to merge PR fails
    Then PR is opened in the browser
    And Engineer is prompted to handle PR manually and run uaccept again

  Scenario: PR in OPEN state: Active Working Change Folder exists
    Given PR associated with the current branch is in OPEN state
    And Working Change Folder is active
    When Engineer invokes uaccept action
    Then Working Change Folder is archived
    And commit is made with message "Archive {wrk_change_folder}"

  Scenario: PR is not in OPEN state
    Given PR associated with the current branch is not in OPEN state
    When Engineer invokes uaccept action
    Then PR is opened in the browser
    And local branch, upstream and remote tracking ref are deleted, errors are ignored
    And Engineer is informed about state and how to restore local branch if needed

  Rule: Edge cases

    Scenario Outline: Validation rejects invalid state
      Given <condition>
      When Engineer invokes uaccept action
      Then AI Agent displays error and stops
      Examples:
        | condition                                    |
        | no git repository                            |
        | working tree has uncommitted changes         |
        | current branch is the default branch         |
        | current branch has no upstream               |
        | not exactly one Working Change Folder exists |

