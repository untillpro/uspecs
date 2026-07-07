Feature: Agentic engineering orchestration
  Engineer runs the agentic engineering script to drive a change from input to completed Construction, optionally opening a pull request

  Rule: Outcomes

    Scenario: Loop reaches a completed Construction section with PR creation enabled
      Given Engineer runs the agentic engineering script with "--pr", input, "--stream dev", and "--agent-tool auggie"
      And the change request and its branch are created
      When an iteration leaves the Change Folder with a Construction section whose checklist items are all checked "[x]"
      Then the loop stops
      And a pull request is created for the change
      And the script exits with status 0

    Scenario: Loop reaches a completed Construction section without PR creation enabled
      Given Engineer runs the agentic engineering script without "--pr"
      And the change request and its branch are created
      When an iteration leaves the Change Folder with a Construction section whose checklist items are all checked "[x]"
      Then the loop stops
      And no pull request is created
      And the script exits with status 0

    Scenario Outline: Loop ends without a completed Construction section
      Given Engineer runs the agentic engineering script with input, "--stream dev", and "--agent-tool claude"
      And the change request and its branch are created
      When <stop_condition>
      And the Change Folder has no Construction section with all checklist items checked "[x]"
      Then the loop stops
      And no pull request is created
      And the script exits with a non-zero status and a diagnostic message
      Examples:
        | stop_condition                                                |
        | an iteration leaves the Change Folder unchanged               |
        | the loop reaches 40 minutes or 40 iterations, whichever first |

  Rule: Loop iteration

    Scenario: An iteration invokes the selected agentic tool once
      Given Engineer runs the agentic engineering script with "--stream dev" and "--agent-tool claude"
      When the loop runs an iteration
      Then the script invokes "claude" once to advance the change through the uspecs workflow
      And the stop conditions are re-evaluated after the iteration

  Rule: Verbose mode

    Scenario: Verbose flag reports execution trace
      Given Engineer runs the agentic engineering script with "-v"
      When the script delegates commands and evaluates loop state
      Then stderr includes issued commands, status, decisions, and summary lines with "[agentic-eng]" category prefixes

  Rule: Delegated steps

    Scenario: Change creation delegates to uchange
      When the agentic engineering script creates the change request from input
      Then it follows the "Create change request" feature in uchange.feature for input handling, branch creation, and Change Folder creation

    Scenario: Input can be read from stdin
      Given Engineer runs the agentic engineering script with "--stdin"
      When stdin contains change input
      Then the script passes that input to uchange

    Scenario: Pull request creation delegates to upr
      Given Engineer runs the agentic engineering script with "--pr"
      When the agentic engineering script opens the pull request
      Then it follows the "Create pull request from current branch" feature in upr.feature

    Scenario Outline: Stream selects the uspecs command namespace
      Given Engineer runs the agentic engineering script with "--pr" and "--stream <stream>"
      When the script delegates to uchange, uimpl, and upr
      Then it uses namespace "<namespace>"
      Examples:
        | stream  | namespace   |
        | dev     | /uspecs-dev |
        | rc      | /uspecs-rc  |
        | release | /uspecs     |

  Rule: Fail fast

    Scenario Outline: Change creation did not produce its preconditions
      Given Engineer runs the agentic engineering script with input, "--stream dev", and "--agent-tool auggie"
      When change request creation completes and <missing> is not created
      Then the loop does not start
      And no pull request is created
      And the script exits with a non-zero status and a diagnostic message
      Examples:
        | missing            |
        | the working branch |
        | the Change Folder  |

  Rule: Argument validation

    Scenario Outline: Required and valid arguments
      When Engineer runs the agentic engineering script <invocation>
      Then error indicates <requirement>
      And no change request is created
      Examples:
        | invocation                                      | requirement                               |
        | without input                                   | input is required                         |
        | with input but no --stream parameter             | --stream is required                      |
        | with --stdin and positional input                | --stdin cannot be used with positional input |
        | with --stdin and empty input                     | stdin input is empty                      |
        | with --stream "prod"                            | the stream must be dev, rc, or release    |
        | with input and --stream but no --agent-tool parameter | --agent-tool is required              |
        | with --agent-tool "codex"                       | --agent-tool must be auggie or claude     |
