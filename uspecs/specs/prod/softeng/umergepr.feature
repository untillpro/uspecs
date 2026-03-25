Feature: Merge pull request
  Engineer asks AI Agent to merge a PR associated with the current branch

  Scenario: PR not found
    Given no open PR exists for the current branch
    When Engineer invokes umergepr action
    Then message "No open PR found for the current branch" is displayed

  Scenario: PR in OPEN state
    Given PR associated with the current branch is in OPEN state
    When Engineer invokes umergepr action
    # Squash and delete local and remote branches
    Then Attempt to merge PR is made with -s -d options
    And Engineer is provided with restore instructions to recover the local branch

  Scenario: PR in OPEN state: Attempt to merge PR fails
    Given Attempt to merge PR fails
    Then PR is opened in the browser
    And Engineer is prompted to handle PR manually and run umergepr again

  Scenario: PR in OPEN state: WCF is active
    Given PR associated with the current branch is in OPEN state
    And Working Change Folder is active
    When Engineer invokes umergepr action
    Then Working Change Folder is archived
    And commit is made with message "Archive {wrk_change_folder}"
    And outcome from the base scenario is followed

  Scenario: PR not in OPEN state
    Given PR associated with the current branch is not in OPEN state
    When Engineer invokes umergepr action
    Then PR is opened in the browser
    And local branch, upstream and remote tracking ref are deleted, errors are ignored
    And Engineer is informed about state and how to restore local branch if needed

  Rule: Edge cases

    Scenario Outline: Validation
      Given <condition>
      When Engineer invokes umergepr action
      Then AI Agent displays error and stops
      Examples:
        | condition                      | message           |
        | current branch has no upstream | same as condition |
      And Examples includes examples from the "Git validations#Git working tree is clean" scenario
      And Examples includes examples from the "Change Folder validations#Exactly one Working Change Folder" scenario
