Feature: Synchronization of Implementation Plan with actual changes

  Engineer synchronizes Implementation Plan with actual changes

  Scenario: Execute uspecs-sync command
    Given Implementation Plan exists
    And Change File has baseline commit in frontmatter
    When Engineer runs uspecs-sync command
    Then AI Agent reads baseline commit from Change File frontmatter
    And AI Agent gets list of files changed since baseline using git diff
    And AI Agent updates Implementation Plan to reflect actual changes
    And AI Agent adds items and sub-items for changes not yet reflected in the Implementation Plan
    And AI Agent updates or removes wrong or outdated items and sub-items
    But AI Agent does not add more than 5 new sub-items per to-do item in a single sync
    And AI Agent never removes correct items and sub-items to reduce their count