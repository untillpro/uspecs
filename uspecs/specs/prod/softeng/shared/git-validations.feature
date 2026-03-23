Feature: Git validations
  Git validations used across multiple features

  Scenario Outline: Project inside Git working tree
    Given <condition>
    When git-dependent action is invoked
    Then AI Agent displays error message and stops
    Examples:
      | condition                                  | message                                    |
      | path <path> is not inside git working tree | path <path> is not inside git working tree |

  Scenario Outline: Git working tree is clean
    Given <condition>
    When action that requires clean git repository is invoked
    Then AI Agent displays error message and stops
    Examples:
      | condition                            | message           |
      | working tree has uncommitted changes | same as condition |
      | current branch is the default branch | same as condition |
    And Examples includes examples from the "Project inside Git working tree" scenario
