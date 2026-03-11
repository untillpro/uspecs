Feature: Create change request
  Engineer asks AI Agent to create change request

  Scenario: Create change request, no options
    When Engineer invokes uchange action
    Then base change request is created
    And Git branch is created with name following branch naming rules

  Scenario Outline: Create change request with issue reference
    Given AI Agent <configured> to fetch issue content from the referenced issue URL
    When Engineer invokes uchange action with issue reference
    Then base change request is created
    And Frontmatter has issue_url value set to the referenced issue URL
    And Issue File <issue-file-created-and-contains> the fetched issue contents in markdown format
    And Change File <references> Issue File in the Why section
    Examples:
      | configured                         | references                    | issue-file-created-and-contains |
      | configured to fetch content        | references Issue File         | contains fetched issue content  |
      | configured not to fetch configured | does not reference Issue File | is not created                  |

  Scenario: Create change request with --no-branch option
    When Engineer invokes uchange action with --no-branch option
    Then base change request is created
    And Git branch is not created

  Scenario: Create change request with --branch option
    When Engineer invokes uchange action with --branch option
    Then base change request is created
    And Git branch is created with name following branch naming rules

  Scenario: All options are independently composable
    When Engineer invokes uchange action with --no-branch option and issue reference
    Then all options are applied

  Rule: Edge cases

    Scenario: --branch and --no-branch are mutually exclusive
      When Engineer invokes uchange action with both --branch and --no-branch options
      Then error is displayed: "--branch and --no-branch are mutually exclusive"
      And change request is not created
