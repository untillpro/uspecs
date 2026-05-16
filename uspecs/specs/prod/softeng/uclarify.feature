Feature: Clarify uncertainties in specifications
  Engineer asks AI Agent to identify uncertainties in a specification or artifact, present options, and integrate the chosen decision

  Scenario: Interactive clarification
    Given Engineer has an open specification or artifact file
    When Engineer invokes uclarify action
    Then AI Agent identifies the most critical uncertainty in the file
    And AI Agent presents a numbered list of solution options with Pros, Cons, and Confidence
    And AI Agent waits for Engineer to pick a number, type a free-form answer, or choose Skip/Cancel

  Scenario: Auto clarification
    Given Engineer has an open specification or artifact file
    When Engineer invokes uclarify action with --auto
    Then AI Agent identifies the three most critical uncertainties in the file
    And AI Agent picks the best solution for each uncertainty
    And AI Agent integrates the three decisions into the specification or artifact
