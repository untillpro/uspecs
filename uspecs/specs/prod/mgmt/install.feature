Feature: Install uspecs
  Engineer installs uspecs for a project

  Scenario Outline: Install stable version
    Given README.md contains <type> install command without --alpha flag
    When Engineer runs the <type> install command
    Then uspecs is installed with <type> invocation type
    And config file is created with version and timestamps
    And <file> is created if it does not exist
    And instructions are injected into <file>

    Examples:
      | type | file      |
      | nlia | AGENTS.md |
      | nlic | CLAUDE.md |

  Scenario: Install alpha version
    When Engineer runs install with --alpha and other flags
    Then uspecs is installed from the latest commit on main branch
    And config file version is "alpha" with commit info
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

