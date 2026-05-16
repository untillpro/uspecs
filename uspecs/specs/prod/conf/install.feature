Feature: Install and update uspecs plugin
  Engineer installs and updates the uspecs framework plugin in an AI agent host by adding the per-agent marketplace, installing the plugin, and later refreshing the marketplace to pick up new versions

  Scenario Outline: Install plugin
    Given Engineer uses agent host <host>
    And the <stream> marketplace repository is "uspecs/<market>"
    When Engineer runs "<cli> plugin marketplace add uspecs/<market>"
    And Engineer runs "<cli> plugin <install> <plugin>@<market>"
    Then the uspecs plugin (<stream> build) is installed into <host>
    Examples:
      | stream      | host         | cli    | install | market                     | plugin     |
      | stable      | Claude Code  | claude | install | uspecs-plugins-claude      | uspecs     |
      | stable      | Augment Code | auggie | install | uspecs-plugins-augment     | uspecs     |
      | stable      | Codex        | codex  | add     | uspecs-plugins-codex       | uspecs     |
      | development | Claude Code  | claude | install | uspecs-dev-plugins-claude  | uspecs-dev |
      | development | Augment Code | auggie | install | uspecs-dev-plugins-augment | uspecs-dev |
      | development | Codex        | codex  | add     | uspecs-dev-plugins-codex   | uspecs-dev |

  Scenario Outline: Update plugin to the latest version
    Given Engineer has previously installed the uspecs plugin from "uspecs/<market>"
    And a newer version of the plugin has been published to "uspecs/<market>"
    When Engineer runs "<cli> plugin marketplace <refresh> <market>"
    And Engineer runs "<cli> plugin <install> <plugin>@<market>"
    Then the uspecs plugin in <host> is updated to the newer version
    Examples:
      | stream      | host         | cli    | refresh | install | market                     | plugin     |
      | stable      | Claude Code  | claude | update  | install | uspecs-plugins-claude      | uspecs     |
      | stable      | Augment Code | auggie | update  | install | uspecs-plugins-augment     | uspecs     |
      | stable      | Codex        | codex  | upgrade | add     | uspecs-plugins-codex       | uspecs     |
      | development | Claude Code  | claude | update  | install | uspecs-dev-plugins-claude  | uspecs-dev |
      | development | Augment Code | auggie | update  | install | uspecs-dev-plugins-augment | uspecs-dev |
      | development | Codex        | codex  | upgrade | add     | uspecs-dev-plugins-codex   | uspecs-dev |
