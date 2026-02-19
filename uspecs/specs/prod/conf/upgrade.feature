Feature: Upgrade uspecs
  Engineer upgrades uspecs to the latest major version

  Scenario Outline: Upgrade stable version
    Given uspecs is installed with stable version
    And a new major version is available
    When Engineer runs "conf.sh upgrade <pr_flag>" and confirms
    Then uspecs is upgraded to the latest major version
    And config file is updated with new version and timestamps
    And <pr_action>

    Examples:
      | pr_flag | pr_action                                          |
      |         | no PR is created                                   |
      | --pr    | PR is created with branch upgrade-uspecs-{version} |

  Rule: Edge cases

    Scenario: Upgrade fails on alpha
      Given uspecs is installed with alpha version
      When Engineer runs "conf.sh upgrade"
      Then upgrade fails with "Only applicable for stable versions. Alpha versions always track the latest commit from main branch, use update instead"

