Feature: Create change request
  Engineer asks AI Agent to create change request

  Scenario: Create change request, no options
    When Engineer invokes uchange action

    # Just change.md with frontmatter
    Then base change request is created

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

  Scenario: Create change request with --branch option
    When Engineer invokes uchange action with --branch option
    Then base change request is created
    And Git branch is created with name following branch naming rules

  Scenario: All options are independently composable
    When Engineer invokes uchange action with --branch option and issue reference
    Then all options are applied
