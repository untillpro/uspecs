Feature: Show plugin version
  Engineer asks AI Agent to show the version of the uspecs framework plugin

  Scenario Outline: Display version and update availability
    Given uspecs plugin is installed from <origin> with version <version>
    And latest uspecs plugin version in the same marketplace stream is <latest_version>
    And update availability can be checked
    When Engineer invokes uversion action
    Then AI Agent displays the uspecs framework plugin version <version>
    And AI Agent displays update availability <availability>
    And AI Agent does not install or update the uspecs plugin
    And AI Agent does not require a separate version-check command
    And if <availability> reports a newer version, AI Agent shows instructions how to update the uspecs plugin to the latest version
    Examples:
      | origin                          | version                       | latest_version                | availability                                          |
      | a stable marketplace build      | "2.3.0"                       | "2.3.0"                       | "up to date"                                          |
      | a stable marketplace build      | "2.3.0"                       | "2.4.0"                       | "newer version 2.4.0 available"                       |
      | a development marketplace build | "2.3.0-dev+20260504-1519.abc" | "2.3.0-dev+20260504-1519.abc" | "up to date"                                          |
      | a development marketplace build | "2.3.0-dev+20260504-1519.abc" | "2.3.0-dev+20260505-0901.def" | "newer version 2.3.0-dev+20260505-0901.def available" |

  Scenario: Display version when update availability cannot be checked
    Given uspecs plugin is installed from a marketplace build with version "2.3.0"
    And latest uspecs plugin version in the same marketplace stream cannot be checked
    When Engineer invokes uversion action
    Then AI Agent displays the uspecs framework plugin version "2.3.0"
    And AI Agent displays update availability "unknown"
    And AI Agent does not install or update the uspecs plugin
    And AI Agent does not require a separate version-check command

  Scenario: Display source repository version without checking update availability
    Given uspecs plugin is running from the uspecs source repository
    And the uspecs source repository reports sentinel version "0.0.0-source"
    When Engineer invokes uversion action
    Then AI Agent displays the uspecs framework plugin version "0.0.0-source"
    And AI Agent skips update availability checking
    And AI Agent does not install or update the uspecs plugin
    And AI Agent does not require a separate version-check command
