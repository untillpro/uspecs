Feature: Install uspecs
  Engineer installs uspecs for a project

  Background:
    Given Engineer is on the "README.md" page

  Scenario: Install alpha version
    When Engineer choose install with --alpha
    Then uspecs is installed from the latest commit on main branch
    And uspecs metadata file is created and describes the alpha version with commit info


  Scenario Outline: Install stable version
    Given uspecs README.md contains install command that uses <method>, without --alpha flag
    When Engineer runs this install command
    Then uspecs is installed with invocation <method>
    And uspecs metadata file is created and describes the stable version
    And <file> is created if it does not exist
    And instructions are injected into <file>

    Examples:
      | method | file      |
      | nlia   | AGENTS.md |
      | nlic   | CLAUDE.md |

  Scenario: Install alpha version from custom branch
    Given USPECS_ALPHA_BRANCH is set to a custom branch name
    When Engineer runs install with --alpha
    Then uspecs is installed from the latest commit on that branch
    And uspecs metadata file describes the alpha version with that branch's commit

  Rule: Edge cases

    Scenario Outline: Installation failure
      Given <condition>
      When Engineer runs install
      Then installation fails with "<message>"

      Examples:
        | condition                   | message                                         |
        | no git repository exists    | No git repository found                         |
        | uspecs is already installed | uspecs is already installed, use update instead |

