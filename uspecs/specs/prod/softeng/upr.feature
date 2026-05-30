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

  ## // TODO: Rename to track origin/current_branch if not tracked yet
  Scenario: No PR for current branch: branch has no upstream
    Given local branch does not track origin/current_branch
    When Engineer invokes upr action
    Then local branch is set to track origin/current_branch
    And outcome from the "No PR for current branch" scenario is followed

  Rule: PR artifacts

    Background:
      Given a PR is being created

    Scenario Outline: Construct PR title and commit message
      Given change.md frontmatter has type <type>, scope <scope>, breaking <breaking>
      And <issue_condition>
      Then PR title is <subject>
      And see_details_line is "See change.md for details"
      And commit subject equals <subject>
      And commit body is <body>
      And change_title is text after ":" in the first `#` heading of change.md, trimmed
      Examples:
        | type     | scope             | breaking | issue_condition                | subject                                           | body                                   |
        | feat     | (absent)          | (absent) | change does not have issue_url | feat: {change_title}                              | {see_details_line}                     |
        | fix      | [softeng]         | (absent) | change does not have issue_url | fix(softeng): {change_title}                      | {see_details_line}                     |
        | feat     | [softeng, devops] | (absent) | change has issue_url           | feat(softeng,devops): {change_title} [{issue_id}] | {see_details_line}\nCloses #{issue_id} |
        | refactor | [softeng]         | true     | change has issue_url           | refactor(softeng)!: {change_title} [{issue_id}]   | {see_details_line}\nCloses #{issue_id} |
        | chore    | (absent)          | true     | change does not have issue_url | chore!: {change_title}                            | {see_details_line}                     |

    Scenario Outline: Construct PR body
      Given change.md has <change_md_shape>
      Then pr_body is composed from change.md with the YAML frontmatter wrapped in a ```yaml fenced code block
      And pr_body includes <body_content>
      And pr_body includes all body content from the first top-level ## section after the main heading
      And pr_body is truncated at 40 lines or 4000 characters, whichever is reached first
      And pr_body appends a details note when content is truncated
      And every relative file link `[text](path)` in pr_body outside fenced code blocks is defanged: leading `(../)+` segments are stripped, a single `/` is prepended to the path, and the whole `[text](path)` literal is wrapped in backticks
      Examples:
        | change_md_shape                                 | body_content                    |
        | a single top-level ## Context section           | the ## Context section          |
        | ## Why and ## What sections                     | the ## Why and ## What sections |
        | ## Why and ## How sections                      | the ## Why and ## How sections  |
        | three top-level ## sections                     | all three top-level ## sections |
        | no top-level ## sections after the main heading | no body sections                |

    Scenario Outline: PR body link handling
      Given change.md body contains a Markdown link with target <link_target> in <link_context>
      Then pr_body renders the link as <rendered_link>
      Examples:
        | link_target                   | link_context           | rendered_link                                                                              |
        | ../../../bin/softeng.sh       | regular paragraph      | `[text](/bin/softeng.sh)` (defanged: prefix stripped, `/` prepended, wrapped in backticks) |
        | ../../../../../bin/softeng.sh | regular paragraph      | `[text](/bin/softeng.sh)` (any depth of `../` is stripped)                                 |
        | https://example.com/page      | regular paragraph      | the link unchanged                                                                         |
        | http://example.com/page       | regular paragraph      | the link unchanged                                                                         |
        | mailto:user@example.com       | regular paragraph      | the link unchanged                                                                         |
        | #section-anchor               | regular paragraph      | the link unchanged                                                                         |
        | /already/root-absolute.md     | regular paragraph      | the link unchanged                                                                         |
        | ./sibling.md                  | regular paragraph      | the link unchanged                                                                         |
        | sibling.md                    | regular paragraph      | the link unchanged                                                                         |
        | ../../../bin/softeng.sh       | inside ``` fenced code | the link unchanged                                                                         |
        | ../../../../../etc/passwd     | regular paragraph      | `[text](/etc/passwd)` (escape-the-repo inputs are treated uniformly; the link is inert)    |

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
