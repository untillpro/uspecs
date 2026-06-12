Feature: Self-review automated review chain
  AI Agent reviews specs or construction after uimpl completes todos or uchange authors a plan section

  # self-review is a top-level softeng command (not under `action`).
  # Usage: bash bin/softeng.sh self-review --type {specs|construction} --stage {A|B} [-b N]
  # Auto-invocation by uimpl and uchange is specified in uimpl.feature and uchange.feature.
  # -b N is a retry budget applicable only to --type specs; see retry budget scenarios below.

  Rule: Core behavior

    Scenario Outline: Stage prompt drives review and chain hand-off
      When AI Agent invokes self-review with --type <type> --stage <stage>
      Then the prompt instructs AI Agent to perform <scope>
      And the prompt instructs AI Agent to <next>
      Examples:
        | type         | stage | scope                                                                   | next                                             |
        | specs        | A     | consistency with change request and DRY across specs and/or to-do items | report results                                   |
        | construction | A     | consistency with change request                                         | invoke self-review --type construction --stage B |
        | construction | B     | DRY and SOLID across construction artifacts                             | report results                                   |

    Scenario: Inline fix and advance
      When AI Agent runs a self-review stage and finds issues
      Then AI Agent fixes the issues inline
      And AI Agent proceeds per the stage's chain or retry instructions, which may re-invoke the same specs stage when a remaining budget is set

  Rule: Specs retry budget

    Scenario Outline: Specs review retry budget propagation
      When AI Agent invokes self-review with --type specs --stage A -b <budget>
      Then the prompt <retry_outcome>
      Examples:
        | budget | retry_outcome                                                                           |
        | 4      | renders a retry block instructing re-invocation with -b 3 when new issues were detected |
        | 1      | renders a retry block instructing re-invocation with -b 0 when new issues were detected |
        | 0      | renders no retry block; the unconditional report-results tail fires                     |

    Scenario: Retry block fires only when new issues were detected during the pass
      When AI Agent runs --type specs --stage A with -b N where N is greater than 0
      Then the retry block in the prompt is conditional on new issues being detected during the pass
      And a clean pass terminates at the report-results tail without re-invoking the stage

    Scenario: -b is rejected for --type construction
      When AI Agent invokes self-review with --type construction --stage A -b 1
      Then error is displayed: "-b requires --type specs"
      And no review is performed

    Scenario: -b rejects negative values
      When AI Agent invokes self-review with --type specs --stage A -b -1
      Then error is displayed indicating -b requires a non-negative integer
      And no review is performed

  Rule: Reporting

    Scenario: End-of-chain report
      When AI Agent completes the last stage in the chain
      Then AI Agent reports issues found and fixes applied to the Engineer
