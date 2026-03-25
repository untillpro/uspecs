Feature: Script execution
  Script execution behaviors used across multiple features

  Scenario: Script exits with error
    When AI Agent runs a script and interprets its output
    And the script exits with error
    Then AI Agent describes what happened
    And AI Agent suggests recovery options
    And AI Agent waits for explicit Engineer permission before taking any further action

