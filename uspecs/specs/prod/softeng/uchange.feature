Feature: Create change request
  Engineer asks AI Agent to create change request

  Scenario Outline: Basic change request creation
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


  Scenario: --how option forces How section creation
    When Engineer invokes uchange action with --how option
    Then base change request is created
    And How section is produced in Change File
    And uimpl action is not invoked automatically

  Rule: Branch creation options

    Scenario: --no-branch option
      When Engineer invokes uchange action with --no-branch option
      Then base change request is created
      And Git branch is not created

    Scenario: --branch option
      When Engineer invokes uchange action with --branch option
      Then base change request is created
      And Git branch is created with name following branch naming rules

    Scenario: error: --fetchable without an issue URL
      When Engineer invokes uchange action with --fetchable but no issue URL
      Then error is displayed: "--fetchable requires an issue URL"
      And change request is not created


  Rule: Handling issue URLs

    Background:
      Given Engineer invokes uchange action with issue URL

    Scenario: Agent is instructed to determine whether issue URL is fetchable
      Given user input contains an issue URL
      When AI Agent reads uchange action instructions
      Then AI Agent is instructed to pass --issue-url {URL}
      And AI Agent is instructed to also pass --fetchable when it can fetch the issue body from that URL

    Scenario: Issue URL is fetchable
      When fetchable status is determined as --fetchable
      Then Frontmatter has issue_url value set to the provided issue URL
      And Change File body begins with a Refs section rendered as a markdown bulleted list before any prose section
      And each Refs entry has the link form "[{issue-number}: {issue-title}](./issue-{issue-number}.md)"
      And Change File body continues with Why and What sections
      And AI Agent extracts {issue-number} from --issue-url per its prompt instructions, independently of the bash extractor used for branch naming and Closes #<id>
      And AI Agent is instructed to fetch the issue and save its body to Issue File named issue-{issue-number}.md as markdown
      And Why and What sections in Change File are populated by AI Agent by distilling the fetched issue in the change's terms, not by verbatim restatement
      And the semantics and per-type guidance for Why and What sections are preserved from the non-fetchable shape

    Scenario: Issue URL is not fetchable
      When fetchable status is determined as omitted
      Then Frontmatter has issue_url value set to the provided issue URL
      And Change File body shape is Why and What sections
      And AI Agent is not instructed to fetch the issue and Issue File is not created

    Scenario Outline: Issue URL: branch naming
      When Engineer invokes uchange action with issue URL <issue_url> and change name <change_name>
      Then Git branch is created with name <branch_name>
      Examples:
        | issue_url                                   | change_name    | branch_name      |
        | https://github.com/owner/repo/issues/42     | my-feature     | 42-my-feature    |
        | https://jira.example.com/browse/PROJ-123    | fix-bug        | PROJ-123-fix-bug |
        | https://gitlab.com/group/project/-/issues/7 | add-validation | 7-add-validation |
        | https://example.com/projects/#!766766       | fix-crash      | 766766-fix-crash |


    Scenario Outline: ## How section under --fetchable
      When Engineer invokes uchange action with --fetchable, an issue URL, <how_flag>, and the issue <approach_in_issue>
      Then ## How section <how_outcome> in Change File
      Examples:
        | how_flag  | approach_in_issue             | how_outcome     |
        | (omitted) | describes an approach         | is produced     |
        | (omitted) | does not describe an approach | is not produced |
        | --how     | describes an approach         | is produced     |
        | --how     | does not describe an approach | is produced     |

  Rule: Chaining to implementation

    Scenario: --no-impl option is a backwards-compatible no-op
      When Engineer invokes uchange action with --no-impl option
      Then the outcome is identical to invocation without the flag

    Scenario: --plan option
      When Engineer invokes uchange action with --plan option
      Then base change request is created
      And uimpl action is invoked automatically

    Scenario Outline: uchange without --plan does not chain self-review
      When Engineer invokes uchange action <invocation>
      Then AI Agent does not invoke self-review
      Examples:
        | invocation                        |
        | with default options              |
        | with --how option                 |
        | with --fetchable and an issue URL |

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