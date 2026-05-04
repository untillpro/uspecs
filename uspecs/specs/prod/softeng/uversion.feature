Feature: Show plugin version
  Engineer asks AI Agent to show the version of the uspecs framework plugin

  Scenario Outline: Display version
    Given uspecs plugin is installed from <origin>
    When Engineer invokes uversion action
    Then AI Agent displays the uspecs framework plugin version <version>
    Examples:
      | origin                                  | version                                |
      | a release marketplace build (core)      | "2.3.0"                                |
      | a dev marketplace build (core+ts+sha)   | "2.3.0-dev+20260504-1519.8da604592d28" |
      | the uspecs source repository (sentinel) | "0.0.0-source"                         |
