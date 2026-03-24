Feature: Create pull request from current branch
  Engineer asks AI Agent to create a pull request from the current branch

  Scenario Outline: PR exists for current branch
    Given a PR in <pr_state> state is associated with the current branch
    When Engineer invokes upr action
    Then <action> is performed
    Examples:
      | pr_state | action                                                                                   |
      | OPEN     | PR URL is displayed, message "A PR already exists" is shown, and PR is opened in browser |
      | CLOSED   | new PR creation proceeds normally (open browser, squash only if more than one commit)    |
      | MERGED   | Engineer is notified that PR was already merged and new PR creation proceeds normally    |

  Scenario: No PR for current branch: single commit
    Given no PR is associated with the current branch
    And the branch contains exactly one commit since merge-base with pr_remote/default_branch
    When Engineer invokes upr action
    Then pr_remote/default_branch is fetched
    And squash and force-push are skipped
    And PR creation is opened in the browser with pr_title and pr_body
    And Engineer is prompted with next steps (no restore instructions)

  Scenario: No PR for current branch: multiple commits
    Given no PR is associated with the current branch
    And the branch contains more than one commit since merge-base with pr_remote/default_branch
    When Engineer invokes upr action
    Then pr_remote/default_branch is fetched
    And branch is squashed into a single commit with commit_message
    And branch is force-pushed
    And PR creation is opened in the browser with pr_title and pr_body
    And Engineer is provided with restore instructions to revert the squash
    And Engineer is prompted with next steps

  Scenario: No PR for current branch: WCF is active
    Given Working Change Folder is active
    When Engineer invokes upr action
    Then Working Change Folder remains active (not archived)
    And outcome from the "No PR for current branch: single commit" scenario is followed

  Scenario: No PR for current branch: branch has no upstream
    Given local branch does not track origin/current_branch
    When Engineer invokes upr action
    Then local branch is set to track origin/current_branch
    And outcome from the "No PR for current branch: single commit" scenario is followed

  Scenario Outline: No PR for current branch: PR title and commit message
    Given no PR is associated with the current branch
    And <issue_condition>
    When Engineer invokes upr action
    Then PR title is <title_format>
    And pr_body is content of change.md with YAML frontmatter --- delimiters stripped (fields kept as plain text)
    And pr_body is truncated to 4000 characters with "(truncated -- see change.md for full details)" appended when exceeded
    And see_details_line is "See change.md for details"
    And when squashing (multiple commits), commit message is <message_format>
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
