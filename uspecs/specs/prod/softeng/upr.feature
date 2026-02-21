Feature: Create pull request from change branch
  Engineer asks AI Agent to create a pull request from the current change branch

  Scenario: Create pull request
    When Engineer invokes upr action
    Then AI Agent asks confirmation before proceeding
    And pull request is created with a single squashed commit
    And change branch is removed
    And Engineer is on the PR branch
    And AI Agent reports pull request URL to Engineer

  Scenario Outline: PR title and body include issue reference when available
    Given <issue_condition>
    When Engineer invokes upr action
    Then PR title is <title_format>
    And PR body is <body_format>
    Examples:
      | issue_condition                | title_format                   | body_format                                                 |
      | change has issue_url           | [{issue_id}] {draft_title} | [{issue_id}]({issue_url}) {draft_title}\n\n{draft_body} |
      | change does not have issue_url | {draft_title}                  | {draft_title}\n\n{draft_body}                               |

  Rule: Edge cases

    Scenario Outline: Validation rejects invalid state
      Given <condition>
      When Engineer invokes upr action
      Then AI Agent displays error and stops
      Examples:
        | condition                            |
        | no git repository                    |
        | working tree has uncommitted changes |
        | current branch is the default branch |
        | current branch ends with --pr        |
        | PR branch already exists             |

    Scenario: Merge conflicts with default branch
      Given change branch has conflicts with the default branch
      When Engineer invokes upr action
      Then AI Agent reports merge conflict and asks Engineer to resolve and re-run

    Scenario: Failure during PR creation preserves change branch
      Given PR creation fails after PR branch was created
      When error is handled
      Then PR branch is cleaned up
      And change branch is preserved

