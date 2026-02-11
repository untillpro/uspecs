Feature: Implementation approach guidance

  Engineer gets an idea about implementation approach for a Change Request

  Scenario Outline: Execute uspecs-how command
    Given <condition>
    When Engineer runs uspecs-how command
    Then AI Agent <action>
    Examples:
      | condition               | action                                                  |
      | How File does not exist | creates How File with Approach                          |
      | How File exists         | adds key elements from tmpl-td.md per AI Agent decision |

