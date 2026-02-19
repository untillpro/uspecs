Feature: Configure invocation methods
  Engineer adds or removes invocation methods

  Scenario Outline: Manage invocation method
    When Engineer runs "conf.sh it <action> <type>"
    Then <file> is created if it does not exist
    And instructions are <result> in <file>
    And config file invocation_methods list is updated

    Examples:
      | action   | type | file      | result       |
      | --add    | nlia | AGENTS.md | injected     |
      | --add    | nlic | CLAUDE.md | injected     |
      | --remove | nlia | AGENTS.md | removed from |
      | --remove | nlic | CLAUDE.md | removed from |

