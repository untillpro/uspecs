Feature: PR management
  Developer manages pull requests via GitHub comments and automated workflows

  Scenario: PR accept comment
    Given a pull request is open
    And Developer has Write access to the repository
    When Developer posts a comment "uaccept" on the pull request
    Then the comment receives a +1 reaction
    And uspecs archiveall command is executed
    And pull request is merged with squash option
    And remote PR branch is deleted
    And Developer is notified to run uarchive to remove local PR branch

