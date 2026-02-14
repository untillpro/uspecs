Feature: Upgrade uspecs
  Engineer upgrades uspecs to the latest major version

  Scenario: Upgrade stable version
    Given uspecs is installed with stable version
    And a new major version is available
    When Engineer runs upgrade and confirms
    Then uspecs is upgraded to the latest major version
    And config file is updated with new version and timestamps

  Scenario: Upgrade fails on alpha
    Given uspecs is installed with alpha version
    When Engineer runs upgrade
    Then upgrade fails with error suggesting to use update instead

