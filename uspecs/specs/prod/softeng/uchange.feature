Feature: Create change request
  Engineer asks AI Agent to create change request

  Rule: Core behavior

    Scenario Outline: Mandatory options only
      Given Engineer is on <branch>
      When Engineer invokes uchange action with --type <type>
      Then base change request is created with Why and What sections
      And Frontmatter has type field set to <type>
      And Git branch <branch_outcome>
      And uimpl action is not invoked automatically
      Examples:
        | branch               | type | branch_outcome                                     |
        | the default branch   | feat | is created with name following branch naming rules |
        | a non-default branch | fix  | is not created                                     |

  Rule: Options

    Scenario Outline: Issue reference provided
      When Engineer invokes uchange action with issue reference and <fetchable_flag>
      Then base change request is created
      And Frontmatter has issue_url value set to the referenced issue URL
      And Change File body shape is <body_shape>
      And AI Agent <fetch_instruction>
      Examples:
        | fetchable_flag | body_shape                  | fetch_instruction                                                            |
        | --fetchable    | ## Context section          | is instructed to fetch the issue and save its body to Issue File as markdown |
        | (omitted)      | ## Why and ## What sections | is not instructed to fetch the issue and Issue File is not created           |

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

    Scenario: --no-impl option is a backwards-compatible no-op
      When Engineer invokes uchange action with --no-impl option
      Then the outcome is identical to invocation without the flag

    Scenario: --how option
      When Engineer invokes uchange action with --how option
      Then base change request is created
      And ## How section is produced in Change File
      And uimpl action is not invoked automatically

    Scenario: --plan option
      When Engineer invokes uchange action with --plan option
      Then base change request is created
      And uimpl action is invoked automatically

    Scenario: --specs option
      When Engineer invokes uchange action with --specs option
      Then base change request is created
      And specs folder is created if it does not exist

  Rule: Edge cases

    Scenario: --branch and --no-branch are mutually exclusive
      When Engineer invokes uchange action with both --branch and --no-branch options
      Then error is displayed: "--branch and --no-branch are mutually exclusive"
      And change request is not created

    Scenario: --type option is missing
      When Engineer invokes uchange action without --type option
      Then error is displayed indicating --type is required and AI Agent is instructed to read the allowed Conventional Commits types from the uchange dispatch instructions and present them to the Engineer
      And change request is not created

    Scenario Outline: --no-impl combined with --how or --plan
      When Engineer invokes uchange action with --no-impl and <other> options
      Then error is displayed: "--no-impl cannot be combined with --how or --plan"
      And change request is not created
      Examples:
        | other  |
        | --how  |
        | --plan |

    Scenario: --fetchable without an issue reference
      When Engineer invokes uchange action with --fetchable but no issue reference
      Then error is displayed: "--fetchable requires an issue reference"
      And change request is not created
