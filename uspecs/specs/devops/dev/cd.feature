Feature: Continuous delivery of plugins to per-agent repositories
  Plugin contents are automatically delivered to per-agent external repositories,
  with destination and version scheme driven by version.txt and the source branch

  Rule: Routing by version.txt

    Scenario Outline: Pre-release `-dev` version routes to Dev Plugin Repositories
      Given version.txt is "<version>"
      When CD workflow runs for agent "<agent>"
      Then plugin is delivered to "<dev_repo>"
      And plugin version is "<core>-dev+<TS>.<SHORT_SHA>"
      Examples:
        | version   | agent   | dev_repo                                             | core  |
        | 2.3.0-dev | claude  | https://github.com/uspecs/uspecs-dev-plugins-claude  | 2.3.0 |
        | 2.3.0-dev | augment | https://github.com/uspecs/uspecs-dev-plugins-augment | 2.3.0 |
        | 2.3.0-dev | codex   | https://github.com/uspecs/uspecs-dev-plugins-codex   | 2.3.0 |

    Scenario Outline: Pre-release `-rc` version routes to RC Plugin Repositories
      Given version.txt is "<version>"
      When CD workflow runs for agent "<agent>"
      Then plugin is delivered to "<rc_repo>"
      And plugin version is "<core>-rc+<TS>.<SHORT_SHA>"
      Examples:
        | version  | agent   | rc_repo                                             | core  |
        | 2.3.0-rc | claude  | https://github.com/uspecs/uspecs-rc-plugins-claude  | 2.3.0 |
        | 2.3.0-rc | augment | https://github.com/uspecs/uspecs-rc-plugins-augment | 2.3.0 |
        | 2.3.0-rc | codex   | https://github.com/uspecs/uspecs-rc-plugins-codex   | 2.3.0 |

    Scenario Outline: Stable version routes to Release Plugin Repositories
      Given version.txt is "<version>"
      When CD workflow runs for agent "<agent>"
      Then plugin is delivered to "<release_repo>"
      And plugin version is "<version>"
      Examples:
        | version | agent   | release_repo                                     |
        | 2.3.0   | claude  | https://github.com/uspecs/uspecs-plugins-claude  |
        | 2.3.0   | augment | https://github.com/uspecs/uspecs-plugins-augment |
        | 2.3.0   | codex   | https://github.com/uspecs/uspecs-plugins-codex   |

  Rule: Triggers

    Scenario: Push to main delivers dev stream
      Given version.txt on `main` is "2.3.0-dev"
      When a commit is pushed to `main`
      Then CD workflow runs for all agents
      And each agent's Dev Plugin Repository receives a new commit

    Scenario: Push to rc delivers rc stream
      Given version.txt on `rc` is "2.3.0-rc"
      When a commit is pushed to `rc`
      Then CD workflow runs for all agents
      And each agent's RC Plugin Repository receives a new commit

    Scenario: Push to release delivers release stream
      Given version.txt on `release` is "2.3.0"
      When a commit is pushed to `release`
      Then CD workflow runs for all agents
      And each agent's Release Plugin Repository receives a new commit
      And lightweight tag "v2.3.0" is (re)created on the same commit

    Scenario: Patch branches do not trigger CD
      Given a `patch-2.3.1` branch exists
      When a commit is pushed to `patch-2.3.1`
      Then CD workflow does not run

    Scenario: Manual workflow_dispatch routes by ref's version.txt
      Given Maintainer triggers CD workflow on a chosen ref
      When CD workflow inspects version.txt on that ref
      Then routing follows the same dev/rc/release rule as automatic triggers

  Rule: rc CD skips anticipatory bumps

    # Suppresses workflow-authored bumps `version 2.3.1-rc`, `version 2.3.2-rc`, ...
    # whose content equals the just-shipped release; the initial `version X.Y.0-rc`
    # and developer cherry-picks still fire CD.
    Scenario Outline: rc CD skips workflow-authored anticipatory bumps
      Given version.txt on `rc` is "<version>"
      And the rc HEAD commit subject is "<subject>"
      When a commit is pushed to `rc`
      Then CD workflow run is "<result>"
      Examples:
        | version  | subject             | result  |
        | 2.3.0-rc | version 2.3.0-rc    | runs    |
        | 2.3.1-rc | version 2.3.1-rc    | skipped |
        | 2.3.2-rc | version 2.3.2-rc    | skipped |
        | 2.3.1-rc | fix: backport crash | runs    |

  Rule: Per-agent isolation

    Scenario: One agent's failure does not block others
      Given CD workflow runs with matrix over claude, augment, codex
      When delivery for one agent fails
      Then deliveries for the other agents still complete
      And only the failed agent's job needs to be re-run
      And the workflow status is failed
