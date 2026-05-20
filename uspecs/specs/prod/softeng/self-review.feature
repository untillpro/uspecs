Feature: Self-review automated review chain
  AI Agent reviews specs or construction after uimpl completes todos

  # self-review is a top-level softeng command (not under `action`).
  # Usage: bash bin/softeng.sh self-review --type {specs|construction} --stage {A|B|C} [--concurrency]
  # Auto-invocation by uimpl is specified in uimpl.feature.
  # --concurrency is an input flag set by the caller (uimpl) when Construction
  # todos were completed; see uimpl.feature for the evaluation scenario.

  Rule: Core behavior

    Scenario Outline: Stage prompt drives review and chain hand-off
      When AI Agent invokes self-review with --type <type> --stage <stage>
      Then the prompt instructs AI Agent to perform <scope>
      And the prompt instructs AI Agent to <next>
      Examples:
        | type         | stage | scope                                                | next                                                                                                 |
        | specs        | A     | consistency with change request and DRY across specs | report results                                                                                       |
        | construction | A     | consistency with change request                      | invoke self-review --type construction --stage B (propagating --concurrency)                         |
        | construction | B     | DRY and SOLID across construction artifacts          | invoke self-review --type construction --stage C when --concurrency is set, otherwise report results |
        | construction | C     | concurrency issues in construction artifacts         | report results                                                                                       |

    Scenario: Inline fix and advance
      When AI Agent runs a self-review stage and finds issues
      Then AI Agent fixes the issues inline
      And AI Agent advances to the next chained step without re-running the stage

  Rule: Reporting

    Scenario: End-of-chain report
      When AI Agent completes the last stage in the chain
      Then AI Agent reports issues found and fixes applied to the Engineer
