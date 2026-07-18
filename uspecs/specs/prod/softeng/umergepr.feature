Feature: Merge pull request
  Engineer asks AI Agent to merge a PR associated with the current branch

  Scenario: PR not found
    Given no open PR exists for the current branch
    When Engineer invokes umergepr action
    Then message "No open PR found for the current branch" is displayed

  Scenario: PR in non-MERGED, non-OPEN state
    Given PR associated with the current branch is in a non-OPEN, non-MERGED state
    When Engineer invokes umergepr action
    Then PR is opened in the browser
    And no local or remote branches are deleted
    And Engineer is informed about state

  Rule: Handling PR in MERGED state

    Background:
      Given PR associated with the current branch is in MERGED state

    Scenario: PR in MERGED state
      Given local HEAD is fully present in the configured upstream
      When Engineer invokes umergepr action
      Then PR is opened in the browser
      And local branch, upstream tracking ref and origin branch are deleted, errors are ignored
      And Engineer is informed about state and how to restore local branch if needed

    Scenario: PR in MERGED state with unpushed commits
      Given current branch has commits absent from its configured upstream
      When Engineer invokes umergepr action
      Then Engineer is instructed to push the commits manually
      And local branch, upstream tracking ref and origin branch are retained

    Scenario: PR in MERGED state without upstream branch
      Given configured upstream branch "origin/my-feature" does not exist remotely
      And current branch "my-feature" contains a local-only commit
      When Engineer invokes umergepr action
      Then local default branch is checked out
      And local branch "my-feature" and upstream tracking ref "origin/my-feature" are deleted
      And no remote branch deletion is attempted
      And Engineer is informed about state and how to restore local branch if needed

  Rule: Handling PR in OPEN state

    Background:
      Given PR associated with the current branch is in OPEN state

    Scenario: PR in OPEN state
      Given local HEAD is fully present in the configured upstream
      When Engineer invokes umergepr action
      Then PR branch is updated with latest base via gh pr update-branch
      # Squash and delete local and remote branches
      And Attempt to merge PR is made with -s -d options
      And pr_url is displayed in the success message
      And Engineer is provided with restore instructions to recover the local branch

    Scenario: PR in OPEN state with pre-existing unpushed commits
      Given current branch has commits absent from its configured upstream
      When Engineer invokes umergepr action
      Then Engineer is instructed to push the commits manually
      And Working Change Folder is not archived
      And PR branch is not updated or merged

    Scenario: PR in OPEN state without upstream branch
      Given configured upstream branch "origin/my-feature" does not exist remotely
      When Engineer invokes umergepr action
      Then Engineer is instructed how to recreate upstream branch "origin/my-feature"
      And Working Change Folder is not archived
      And PR branch is not updated or merged

    Scenario: PR in OPEN state: Attempt to merge PR fails
      When Attempt to merge PR fails
      Then PR is opened in the browser
      And Engineer is prompted to handle PR manually and run umergepr again

    Scenario: PR in OPEN state: WCF is active
      Given Working Change Folder is active
      When Engineer invokes umergepr action
      Then Working Change Folder is archived
      And commit is made with message "Archive {wrk_change_folder}"
      And archive commit is pushed automatically to the configured upstream
      And outcome from the base scenario is followed

    Scenario Outline: PR in OPEN state: Archive commit cannot be confirmed upstream
      Given Working Change Folder is active
      When <condition>
      Then umergepr action stops with an error
      And PR branch is not updated or merged
      Examples:
        | condition                                           |
        | automatic push of the archive commit fails          |
        | configured upstream still lacks the archive commit  |

    Scenario: PR in OPEN state: Configured upstream tracking information is stale
      Given latest configured upstream contains local HEAD
      And local upstream tracking information is stale
      When Engineer invokes umergepr action
      Then latest configured upstream is used to determine that local HEAD is fully pushed
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

  Rule: Working with edge cases

    Scenario Outline: Validation
      Given <condition>
      When Engineer invokes umergepr action
      Then AI Agent displays error and stops
      Examples:
        | condition                      | message           |
        | current branch has no upstream | same as condition |
      And Examples includes examples from the "Git validations#Git working tree is clean" scenario
      And Examples includes examples from the "Change Folder validations#Exactly one Working Change Folder" scenario
