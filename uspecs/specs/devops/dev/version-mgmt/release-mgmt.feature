Feature: Release management
  Maintainer creates releases by tagging versions and preparing next development cycle

  Scenario: Maintainer creates release
    Given current version is "1.0.12-a.4" in version.txt
    And working directory has no uncommitted changes
    And GitHub CLI is installed and authenticated
    When Maintainer runs release script
    Then release version "1.0.12" is created by removing pre-release identifier
    And git tag "1.0.12" is created with annotation "Release 1.0.12"
    And tag "1.0.12" is pushed to origin
    And version branch "version 1.0.12" is created
    And version.txt is updated to "1.1.0-a.0" on the version branch
    And changes are committed with message "Bump version to 1.1.0-a.0 for next development cycle"
    And pull request is created from "version 1.0.12" branch to main
    And Maintainer receives PR URL
    And script switches back to main branch

  Rule: Edge cases

    Scenario: Release script fails when working directory is dirty
      Given current version is "1.0.5-a.2" in version.txt
      And working directory has uncommitted changes
      When Maintainer runs release script
      Then script exits with error "Working directory has uncommitted changes. Commit or stash them first"
      And no tag is created
      And no branch is created

    Scenario: Release script fails when version.txt is missing
      Given version.txt does not exist
      When Maintainer runs release script
      Then script exits with error "version.txt not found at repository root"
      And no tag is created
      And no branch is created

    Scenario: Release script fails when version format is invalid
      Given current version is "invalid-version" in version.txt
      When Maintainer runs release script
      Then script exits with error "Invalid version format: invalid-version (expected X.Y.Z or X.Y.Z-a.N)"
      And no tag is created
      And no branch is created

