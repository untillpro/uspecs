Feature: cwd validations
  cwd validations used across all softeng.sh invocations

  Scenario Outline: cwd is a uspecs skill or plugin root
    Given <condition>
    When any softeng.sh subcommand is invoked
    Then the script exits with error informing AI Agent that it is being run from a uspecs plugin or skill directory and that the uspecs-using project root must be used as cwd
    Examples:
      | condition                                                                            |
      | cwd is a uspecs skill root (cwd contains SKILL.md)                                   |
      | cwd is a uspecs plugin folder (cwd contains .claude-plugin/plugin.json)              |
      | cwd is a uspecs marketplace repo root (cwd contains .claude-plugin/marketplace.json) |
