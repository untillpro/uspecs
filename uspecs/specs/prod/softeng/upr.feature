Feature: Create pull request from current branch
  Engineer asks AI Agent to create a pull request from the current branch

  Scenario Outline: PR exists for current branch
    Given a PR in <pr_state> state is associated with the current branch
    When Engineer invokes upr action
    Then <action> is performed
    Examples:
      | pr_state | action                                                                                   |
      | OPEN     | PR URL is displayed, message "A PR already exists" is shown, and PR is opened in browser |
      | CLOSED   | new PR creation proceeds normally (create PR, open in browser)                           |
      | MERGED   | Engineer is notified that PR was already merged and new PR creation proceeds normally    |

  Scenario: No PR for current branch
    Given no PR is associated with the current branch
    When Engineer invokes upr action
    Then pr_remote/default_branch is fetched
    And branch is squashed into a single commit with commit_message
    And branch is force-pushed
    And PR is created via gh CLI with pr_title and pr_body
    And PR is opened in browser
    And Engineer is provided with restore instructions to revert the squash
    And Engineer is prompted with next steps

  Scenario: No PR for current branch: WCF is active
    Given Working Change Folder is active
    When Engineer invokes upr action
    Then Working Change Folder remains active (not archived)
    And outcome from the "No PR for current branch" scenario is followed

  Scenario: No PR for current branch: branch has no upstream
    Given local branch does not track origin/current_branch
    When Engineer invokes upr action
    Then local branch is set to track origin/current_branch
    And outcome from the "No PR for current branch" scenario is followed

  Scenario Outline: No PR for current branch: PR title and commit message
    Given no PR is associated with the current branch
    And change.md frontmatter has type <type>, scope <scope>, breaking <breaking>
    And <issue_condition>
    When Engineer invokes upr action
    Then PR title is <subject>
    And pr_body is composed from change.md with the YAML frontmatter wrapped in a ```yaml fenced code block, followed by the Why and What sections
    And pr_body is truncated to 40 lines or 4000 characters (whichever hits first) with "(truncated -- see change.md for full details)" appended when exceeded
    And see_details_line is "See change.md for details"
    And commit subject equals <subject>
    And commit body is <body>
    And change_title is text after ":" in the first `#` heading of change.md, trimmed
    Examples:
      | type     | scope          | breaking | issue_condition                | subject                                           | body                                   |
      | feat     | (absent)       | (absent) | change does not have issue_url | feat: {change_title}                              | {see_details_line}                     |
      | fix      | softeng        | (absent) | change does not have issue_url | fix(softeng): {change_title}                      | {see_details_line}                     |
      | feat     | softeng,devops | (absent) | change has issue_url           | feat(softeng,devops): {change_title} [{issue_id}] | {see_details_line}\nCloses #{issue_id} |
      | refactor | softeng        | true     | change has issue_url           | refactor(softeng)!: {change_title} [{issue_id}]   | {see_details_line}\nCloses #{issue_id} |
      | chore    | (absent)       | true     | change does not have issue_url | chore!: {change_title}                            | {see_details_line}                     |

  Rule: Edge cases

    Scenario Outline: Validation
      Given <condition>
      When Engineer invokes upr action
      Then AI Agent displays error <message> and stops
      Examples:
        | condition                                                                     | message                                                                                                                                                                                                              |
        | no changes detected in the current branch since branching from default branch | same as condition                                                                                                                                                                                                    |
        | change.md frontmatter does not contain a `type:` field                        | error directs AI Agent to read allowed Conventional Commits types from the uchange dispatch instructions and present them to the user with a prompt to add `type: <value>` (softeng.sh does not enumerate the types) |
      And Examples includes examples from the "Git validations#Git working tree is clean" scenario
      And Examples includes examples from the "Change Folder validations#All todo items are completed" scenario
      And Examples includes examples from the "Change Folder validations#Exactly one Working Change Folder" scenario
      And PR is not created in any error case
