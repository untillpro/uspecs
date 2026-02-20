Feature: Archive change request
  Engineer archives a completed change request

  Scenario Outline: Archive change request
    Given <condition>
    When Engineer asks AI Agent to archive change request
    Then <outcome>
    Examples:
      | condition                              | outcome                                                     |
      | Active Change Folder is unambiguous    | Active Change Folder is moved to changes archive            |
      | Active Change Folder name is ambiguous | AI Agent asks Engineer to specify Active Change Folder name |

