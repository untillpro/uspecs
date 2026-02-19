Feature: Install uspecs
  Engineer installs uspecs for a project

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

  Scenario: Install alpha version
    When Engineer runs install with --alpha and other flags
    Then uspecs is installed from the latest commit on main branch
    And uspecs metadata file is created and describes the alpha version
    And other flags are respected as in stable install

  Rule: Edge cases

    Scenario Outline: Installation failure
      Given <condition>
      When Engineer runs install
      Then installation fails with "<message>"

      Examples:
        | condition                   | message                                         |
        | no git repository exists    | No git repository found                         |
        | uspecs is already installed | uspecs is already installed, use update instead |

