Feature: Implementation plan management

  Engineer implements change request

  Scenario Outline: Execute uspecs-impl command, all to-do items checked
    Given all to-do items in Implementation Plan are checked
    When Engineer runs uspecs-impl command
    Then Implementation Plan is created if not existing
    And AI Agent executes only one (the first available) <action> depending on <condition>
    Examples:
      | condition                                                                | action                                                                                |
      | `Functional design` section does not exist and it is needed              | Create `Functional design` section with checkbox items referencing spec files         |
      | `Provisioning and configuration` section does not exist and it is needed | Create `Provisioning and configuration` section with installation/configuration steps |
      | `Technical design` section does not exist and it is needed               | Create `Technical design` section with checkbox items referencing design files        |
      | `Construction` section does not exist and it is needed                   | Create `Construction` section and optionally `Quick start` section                    |
      | Nothing of the above                                                     | Display message "No action needed"                                                    |
    And AI Agent stops execution after performing the action

  Scenario: Execute uspecs-impl command, some to-do items unchecked
    Given some to-do items in Implementation Plan are unchecked
    When Engineer runs uspecs-impl command
    Then AI Agent implements each unchecked To-Do Item and checks it immediately after implementation
    But it stops on Review Item if it is unchecked

  Rule: Edge cases

    Scenario: No Active Change Request exists
      Given no Active Change Request exists in changes folder
      When Engineer runs uspecs-impl command
      Then AI Agent displays error "No Active Change Request found"
      And Implementation Plan is not created

    Scenario: Multiple Active Change Requests exist
      Given multiple Active Change Requests exist in changes folder
      And AI Agent may not infer from the context which one to use
      When Engineer runs uspecs-impl command
      Then AI Agent displays error "Multiple Active Change Requests found. Please specify which one to use"
      And lists all Active Change Request folders
      And allows Engineer to select one and proceed