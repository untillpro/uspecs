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

  Scenario Outline: uchange does not chain self-review
    When Engineer invokes uchange action <invocation>
    Then AI Agent does not invoke self-review
    Examples:
      | invocation                        |
      | with default options              |
      | with --fetchable and an issue URL |

  Scenario: --specs option
    When Engineer invokes uchange action with --specs option
    Then base change request is created
    And specs folder is created if it does not exist

  Rule: Domain frontmatter

    Scenario Outline: Domain frontmatter emission
      Given project domain specifications <exist>
      When AI Agent reads uchange action instructions
      Then AI Agent is <instructed> to scan uspecs/specs/*/domain.md and set "domains" frontmatter field to a YAML flow list of affected domains
      And AI Agent is <instructed> to do best-effort inference of affected domains from the matched directory names when the change input is ambiguous about affected domains
      Examples:
        | exist        | instructed     |
        | exist        | instructed     |
        | do not exist | not instructed |

    Scenario: Domain terminology guidance
      Given project domain specifications exist
      When AI Agent reads uchange action instructions
      Then AI Agent is instructed to use relevant domain concepts and terminology while authoring the change request

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
      When AI Agent reads uchange action instructions
      Then AI Agent is instructed to check if input contains issue URL
      And Agent is instructed to pass the URL (if any) as --issue-url option to the softeng.sh
      And AI Agent is instructed to pass --fetchable when it can fetch the issue body from that URL

    Scenario: Issue URL is fetchable
      When fetchable status is determined as --fetchable
      Then Frontmatter has issue_url value set to the provided issue URL
      And Change File body begins with a Resolves: list rendered as a markdown bulleted list before any prose section
      And each Resolves entry has the link form "[{issue-number}: {issue-title}](./issue-{issue-number}.md)"
      And Change File body continues with Why and What sections
      And AI Agent extracts {issue-number} from --issue-url per its prompt instructions, independently of the bash extractor used for branch naming and Closes #<id>
      And AI Agent is instructed to fetch the issue and save its body to Issue File named issue-{issue-number}.md as markdown
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

  Rule: Edge cases

    Scenario: --branch and --no-branch are mutually exclusive
      When Engineer invokes uchange action with both --branch and --no-branch options
      Then error is displayed: "--branch and --no-branch are mutually exclusive"
      And change request is not created

    Scenario: --type option is missing
      When Engineer invokes uchange action without --type option
      Then error is displayed indicating --type is required and AI Agent is instructed to read the allowed Conventional Commits types from the uchange dispatch instructions and present them to the Engineer
      And change request is not created

    Scenario Outline: Removed planning options are rejected
      When Engineer invokes uchange action with <option> option
      Then error is displayed indicating <option> is an unknown argument
      And change request is not created
      Examples:
        | option           |
        | --how            |
        | --plan           |
        | --no-impl        |
        | --no-self-review |

  Rule: Fault localization signal in fix-type What flowchart

    Scenario: Fault is not localized within the bounded investigation
      Given Engineer invokes uchange action with --type fix
      When AI Agent cannot localize the fault within the bounded static investigation
      Then the What section flowchart contains a `?` step annotated `<-- fault: not yet localized`

    Scenario: Fault is localized
      Given Engineer invokes uchange action with --type fix
      When AI Agent localizes the fault within the bounded static investigation
      Then the What section flowchart names the fault on a concrete step
      And the flowchart contains no unlocalized fault marker

    Scenario: Investigation bounds
      When AI Agent reads uchange action instructions for --type fix
      Then AI Agent is instructed to bound fault localization to a static investigation: reading and searching the codebase only
      And AI Agent is instructed not to run code or tests and not to reproduce the symptom
      And AI Agent is instructed to cap the investigation at roughly 5 searches and 10 file reads, stopping earlier when pinning the fault would require verification rather than reading
