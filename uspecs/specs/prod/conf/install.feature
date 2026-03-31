Feature: Install uspecs
  Engineer installs uspecs for a project

  Scenario Outline: Install stable version
    Given uspecs README.md contains install command that uses <method>, without --alpha flag
    When Engineer runs this install command
    Then uspecs is installed with invocation <method>
    And uspecs metadata file is created and describes the stable version
    And <file> is created if it does not exist
    And instructions are injected into <file>

    Examples:
      | method | file      |
      | nlia   | AGENTS.md |
      | nlic   | CLAUDE.md |

  Scenario: Install alpha version
    When Engineer runs install with --alpha and other flags
    Then uspecs is installed from the latest commit on main branch
    And uspecs metadata file is created and describes the alpha version
    And other flags are respected as in stable install

  Scenario: Install local version
    When Engineer runs install with --local and other flags
    Then uspecs is installed from the local repository without downloading from GitHub
    And uspecs metadata file is created with local version and commit info
    And other flags are respected as in stable install

  Scenario: Install with --override
    When Engineer runs install with --override and other flags
    Then uspecs is installed even if it is already installed
    And existing installation is replaced regardless of version
    And other flags are respected as in stable install

  Rule: Curl-pipe install

    Scenario: Install via curl pipe
      Given Engineer runs the README install command (curl ... | bash -s install ...)
      Then conf.sh executes without sourcing any local files (_lib/*, utils.sh)
      And conf.sh uses only curl, mktemp, trap, and bash builtins
      And conf.sh downloads the archive and delegates to the downloaded conf.sh apply

  Rule: Private repositories

    Scenario: Install from a private repository
      Given the GitHub repository is private
      When Engineer sets USPECS_GITHUB_TOKEN environment variable to a valid GitHub token
      Then all GitHub API and download requests include the Authorization header
      And install, update, upgrade, and invocation method commands work as expected

  Rule: Edge cases

    Scenario Outline: Installation failure
      Given <condition>
      When Engineer runs install
      Then installation fails with "<message>"

      Examples:
        | condition                                        | message                                         |
        | no git repository exists                         | No git repository found                         |
        | uspecs is already installed (without --override) | uspecs is already installed, use update instead |
        | working directory is not clean (--pr)            | Working directory has uncommitted changes       |

