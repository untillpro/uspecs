Feature: Update uspecs
  Engineer updates uspecs to the latest version

  Scenario Outline: Update when new version is available
    Given uspecs is installed with <version_type> version
    And a new version is available
    When Engineer runs "manage.sh update" and confirms
    Then uspecs is updated to <target>
    And config file is updated with new version and timestamps

    Examples:
      | version_type | target                         |
      | alpha        | latest commit from main branch |
      | stable       | latest minor version           |

  Scenario Outline: No new version available
    Given uspecs is installed with <version_type> version
    And <availability_condition>
    When Engineer runs "manage.sh update"
    Then "<message>" is printed
    And <upgrade_hint>

    Examples:
      | version_type | availability_condition              | message                                    | upgrade_hint                                                                     |
      | alpha        | no new version is available         | Already on the latest alpha version        |                                                                                  |
      | stable       | no new minor version is available   | Already on the latest stable minor version |                                                                                  |
      | stable       | no new minor but major is available | Already on the latest stable minor version | "Upgrade available to version X.Y.Z, use `manage.sh upgrade` command" is printed |

