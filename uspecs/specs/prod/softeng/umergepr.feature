Feature: Merge pull request
  Engineer asks AI Agent to merge a PR associated with the current branch

  Scenario: PR not found
    Given no open PR exists for the current branch
    When Engineer invokes umergepr action
    Then message "No open PR found for the current branch" is displayed

  Scenario: PR not in OPEN state
    Given PR associated with the current branch is not in OPEN state
    When Engineer invokes umergepr action
    Then PR is opened in the browser
    And local branch, upstream and remote tracking ref are deleted, errors are ignored
    And Engineer is informed about state and how to restore local branch if needed

  Rule: PR in OPEN state

    Background:
      Given PR associated with the current branch is in OPEN state

    Scenario: PR in OPEN state
      When Engineer invokes umergepr action
      Then PR branch is updated with latest base via gh pr update-branch
      # Squash and delete local and remote branches
      And Attempt to merge PR is made with -s -d options
      And pr_url is displayed in the success message
      And Engineer is provided with restore instructions to recover the local branch

    Scenario: PR in OPEN state: Attempt to merge PR fails
      When Attempt to merge PR fails
      Then PR is opened in the browser
      And Engineer is prompted to handle PR manually and run umergepr again

    Scenario: PR in OPEN state: WCF is active
      Given Working Change Folder is active
      When Engineer invokes umergepr action
      Then Working Change Folder is archived
      And commit is made with message "Archive {wrk_change_folder}"
      And outcome from the base scenario is followed

    Scenario: PR in OPEN state: upstream remote exists
      Given upstream remote exists
      When Attempt to merge PR succeeds
      Then branch is deleted from origin (fork) if it exists, via git push origin --delete
      And local default branch is checked out
      And pr_remote/default_branch is fetched
      And if local default branch has diverged from pr_remote/default_branch, divergence details are logged and sync is skipped
      And if fast-forward is possible, fetch+ff is retried for up to 5 seconds until WCF in the default branch is detected
      And default_branch is pushed to origin after fast-forward
      And errors are logged but do not block completion

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
