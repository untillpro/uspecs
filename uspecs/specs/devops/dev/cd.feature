Feature: Continuous delivery of plugins to per-agent repositories
  Plugin contents are automatically delivered to per-agent external repositories,
  with destination and version scheme driven by version.txt

  Rule: Routing by version.txt

    Scenario Outline: Pre-release version routes to Dev Plugin Repositories
      Given version.txt is "<version>"
      When CD workflow runs for agent "<agent>"
      Then plugin is delivered to "<dev_repo>"
      And plugin version is "<core>-dev+<TS>.<SHORT_SHA>"
      Examples:
        | version   | agent   | dev_repo                                          | core  |
        | 2.3.0-dev | claude  | https://github.com/uspecs/uspecs-dev-plugins-claude  | 2.3.0 |
        | 2.3.0-dev | augment | https://github.com/uspecs/uspecs-dev-plugins-augment | 2.3.0 |
        | 2.3.0-dev | codex   | https://github.com/uspecs/uspecs-dev-plugins-codex   | 2.3.0 |

    Scenario Outline: Stable version routes to Release Plugin Repositories
      Given version.txt is "<version>"
      When CD workflow runs for agent "<agent>"
      Then plugin is delivered to "<release_repo>"
      And plugin version is "<version>"
      Examples:
        | version | agent   | release_repo                                  |
        | 2.3.0   | claude  | https://github.com/uspecs/uspecs-plugins-claude  |
        | 2.3.0   | augment | https://github.com/uspecs/uspecs-plugins-augment |
        | 2.3.0   | codex   | https://github.com/uspecs/uspecs-plugins-codex   |

  Rule: Triggers

    Scenario: Push to main delivers dev stream
      Given version.txt on main is "2.3.0-dev"
      When a commit is pushed to main
      Then CD workflow runs for all agents
      And each agent's Dev Plugin Repository receives a new commit

    Scenario: Tag v* delivers release stream
      Given a tag "v2.3.0" is pushed
      And version.txt at the tagged commit is "2.3.0"
      When CD workflow runs for the tag
      Then CD workflow runs for all agents
      And each agent's Release Plugin Repository receives a new commit

    Scenario: Manual workflow_dispatch routes by ref's version.txt
      Given Maintainer triggers CD workflow on a chosen ref
      When CD workflow inspects version.txt on that ref
      Then routing follows the same dev-vs-release rule as automatic triggers

  Rule: Per-agent isolation

    Scenario: One agent's failure does not block others
      Given CD workflow runs with matrix over claude, augment, codex
      When delivery for one agent fails
      Then deliveries for the other agents still complete
      And only the failed agent's job needs to be re-run
      And the workflow status is failed
