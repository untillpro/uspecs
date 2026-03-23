Feature: Create pull request from current branch
  Engineer asks AI Agent to create a pull request from the current branch

  Scenario Outline: Create pull request, current branch has a PR associated with it
    Given a PR in <pr_state> state is associated with the current branch
    When Engineer invokes upr action
    Then <action> is performed
    Examples:
      | pr_state | action                                                                                |
      | OPEN     | message "A PR already exists for the current branch" is displayed and PR is opened    |
      | CLOSED   | new PR creation proceeds normally (archive, squash, force-push, open browser)         |
      | MERGED   | Engineer is notified that PR was already merged and new PR creation proceeds normally |

  Scenario: Create pull request, current branch does not have a PR associated with it
    When Engineer invokes upr action
    Then pr_remote/default_branch is fetched
    And Working Change Folder is archived if active
    And local branch is set to track origin/current_branch if not already
    And branch is squashed into a single commit with commit_message
    And branch is force-pushed
    And PR creation is opened in the browser with pr_title and commit_message
    And Engineer is prompted with next steps

  Scenario Outline: pr_title and commit_message include issue reference when available
    Given <issue_condition>
    When Engineer invokes upr action
    Then PR title is <title_format>
    And see_details_line is "See {path-from-prj-root-to-change.md} for details"
    And commit message is <message_format>
    And change_title is text after ":" in the first `#` heading of change.md, trimmed
    Examples:
      | issue_condition                | title_format                | message_format                                         |
      | change has issue_url           | [{issue_id}] {change_title} | Closes #{issue_id}: {change_title}\n{see_details_line} |
      | change does not have issue_url | {change_title}              | {change_title}\n{see_details_line}                     |

  Rule: Edge cases

    Scenario Outline: Validation
      Given <condition>
      When Engineer invokes upr action
      Then AI Agent displays error <message> and stops
      Examples:
        | condition                                                                     | message           |
        | no changes detected in the current branch since branching from default branch | same as condition |
      And Examples includes examples from the "Git validations#Git working tree is clean" scenario
      And Examples includes examples from the "Change Folder validations#All todo items are completed" scenario
      And Examples includes examples from the "Change Folder validations#Exactly one Working Change Folder" scenario
