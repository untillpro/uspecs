Feature: Configure invocation types
  Engineer adds or removes invocation types

  Scenario Outline: Manage invocation type
    When Engineer runs "manage.sh it <action> <type>"
    Then instructions are <result> in <file>
    And config file invocation_types list is updated

    Examples:
      | action   | type | file      | result       |
      | --add    | nlia | AGENTS.md | injected     |
      | --add    | nlic | CLAUDE.md | injected     |
      | --remove | nlia | AGENTS.md | removed from |
      | --remove | nlic | CLAUDE.md | removed from |

  Scenario: Add multiple invocation types
    When Engineer runs "manage.sh it --add nlia --add nlic"
    Then instructions are injected into AGENTS.md and CLAUDE.md
    And config file invocation_types list contains nlia and nlic

