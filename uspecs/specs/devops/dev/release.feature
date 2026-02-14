Feature: Release management
  Developer creates releases by tagging versions and preparing next development cycle

  Scenario: Developer triggers release via GitHub Action
    Given current version is "1.7.0-a4" in version.txt
    When Developer triggers Release workflow manually
    Then git tag "v1.7.0" is created with version.txt set to "1.7.0"
    And tag "v1.7.0" is pushed to remote
    And pull request "1.8.0-a0" is created to main with version.txt set to "1.8.0-a0"