Feature: Update uspecs
  Engineer updates uspecs to the latest version

  Scenario Outline: Update when new version is available
    Given uspecs is installed with <version_type> version
    And a new version is available
    When Engineer runs "conf.sh update <pr_flag>" and confirms
    Then uspecs is updated to <target>
    And config file is updated with new version and timestamps
    And <pr_action>

    Examples:
      | version_type | target                         | pr_flag | pr_action                                                          |
      | alpha        | latest commit from main branch |         | no PR is created                                                   |
      | stable       | latest minor version           |         | no PR is created                                                   |
      | alpha        | latest commit from main branch | --pr    | PR is created with branch update-uspecs-alpha-{timestamp}-{commit} |
      | stable       | latest minor version           | --pr    | PR is created with branch update-uspecs-{version}                  |

  Scenario Outline: No new version available
    Given uspecs is installed with <version_type> version
    And <availability_condition>
    When Engineer runs "conf.sh update"
    Then "<message>" is printed
    And <upgrade_hint>

    Examples:
      | version_type | availability_condition              | message                                    | upgrade_hint                                                                   |
      | alpha        | no new version is available         | Already on the latest alpha version        |                                                                                |
      | stable       | no new minor version is available   | Already on the latest stable minor version |                                                                                |
      | stable       | no new minor but major is available | Already on the latest stable minor version | "Upgrade available to version X.Y.Z, use `conf.sh upgrade` command" is printed |

