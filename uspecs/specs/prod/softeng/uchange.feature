Feature: Create change request
  Engineer asks AI Agent to create change request

  Rule: Core behavior

    Scenario Outline: Mandatory options only
      Given Engineer is on <branch>
      When Engineer invokes uchange action with --type <type>
      Then base change request is created with Why and What sections
      And Frontmatter has type field set to <type>
      And Git branch <branch_outcome>
      And uimpl action is invoked automatically
      Examples:
        | branch               | type | branch_outcome                                     |
        | the default branch   | feat | is created with name following branch naming rules |
        | a non-default branch | fix  | is not created                                     |

  Rule: Options

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
      And ## How section is produced in Change File
      But uimpl action is not invoked

    Scenario: --specs option
      When Engineer invokes uchange action with --specs option
      Then base change request is created
      And specs folder is created if it does not exist
      And AI Agent receives Domain specifications, Functional design specifications, and Technical design specifications artdefs

  Rule: Edge cases

    Scenario: --branch and --no-branch are mutually exclusive
      When Engineer invokes uchange action with both --branch and --no-branch options
      Then error is displayed: "--branch and --no-branch are mutually exclusive"
      And change request is not created

    Scenario: --type option is missing
      When Engineer invokes uchange action without --type option
      Then error is displayed indicating --type is required and listing the allowed Conventional Commits types
      And change request is not created
