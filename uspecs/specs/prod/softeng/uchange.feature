Feature: Create change request
  Engineer asks AI Agent to create change request

  Scenario: No options
    When Engineer invokes uchange action
    Then base change request is created
    And Git branch is created with name following branch naming rules
    And uimpl action is invoked automatically

  Scenario Outline: Issue reference provided
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

  Scenario Outline: Issue reference: branch naming
    When Engineer invokes uchange action with issue reference <issue_url> and change name <change_name>
    Then Git branch is created with name <branch_name>
    Examples:
      | issue_url                                   | change_name    | branch_name      |
      | https://github.com/owner/repo/issues/42     | my-feature     | 42-my-feature    |
      | https://jira.example.com/browse/PROJ-123    | fix-bug        | PROJ-123-fix-bug |
      | https://gitlab.com/group/project/-/issues/7 | add-validation | 7-add-validation |
      | https://example.com/projects/#!766766       | fix-crash      | 766766-fix-crash |

  Scenario: --no-branch option
    When Engineer invokes uchange action with --no-branch option
    Then base change request is created
    And Git branch is not created

  Scenario: --branch option
    When Engineer invokes uchange action with --branch option
    Then base change request is created
    And Git branch is created with name following branch naming rules

  Scenario: --no-impl option
    When Engineer invokes uchange action with --no-impl option
    Then base change request is created
    But uimpl action is not invoked

  Rule: Edge cases

    Scenario: --branch and --no-branch are mutually exclusive
      When Engineer invokes uchange action with both --branch and --no-branch options
      Then error is displayed: "--branch and --no-branch are mutually exclusive"
      And change request is not created
