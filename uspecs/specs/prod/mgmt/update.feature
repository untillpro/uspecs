Feature: Update uspecs
  Engineer updates uspecs to the latest version

  Scenario Outline: Update when new version is available
    Given uspecs is installed with <version_type> version
    And a new version is available
    When Engineer runs update and confirms
    Then uspecs is updated to <target>
    And config file is updated with new version and timestamps

    Examples:
      | version_type | target                            |
      | alpha        | latest commit from main branch    |
      | stable       | latest minor version              |

  Scenario Outline: No new version available
    Given uspecs is installed with <version_type> version
    And no new version is available
    When Engineer runs update
    Then "<message>" is printed

    Examples:
      | version_type | message                                       |
      | alpha        | Already on the latest alpha version            |
      | stable       | Already on the latest stable minor version     |

  Scenario: Stable version with major upgrade available
    Given uspecs is installed with stable version
    And no new minor version is available
    And a new major version is available
    When Engineer runs update
    Then upgrade availability is printed with manage.sh upgrade hint

