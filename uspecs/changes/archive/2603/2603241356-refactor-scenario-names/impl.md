# Implementation plan: Refactor scenario names

## Functional design

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - rename: "Create pull request, current branch has a PR associated with it" -> "PR exists for current branch"
  - rename: "Create pull request, current branch does not have a PR associated with it" -> "No PR for current branch" (remove "if active" and "if not already" steps from base)
  - add: "No PR for current branch: WCF is active" -- delegates to base via "And outcome from the base scenario is followed"
  - add: "No PR for current branch: branch has no upstream" -- delegates to base via "And outcome from the base scenario is followed"
  - rename: "pr_title and commit_message include issue reference when available" -> "No PR for current branch: PR title and commit message"

- [x] update: [softeng/uaccept.feature](../../../../specs/prod/softeng/uaccept.feature)
  - rename: "PR in OPEN state: Active Working Change Folder exists" -> "PR in OPEN state: WCF is active"
  - rename: "PR is not in OPEN state" -> "PR not in OPEN state"

## Construction

- [x] update: [tests/sys/uspecs.sh-prompt-upr.bats](../../../../../tests/sys/uspecs.sh-prompt-upr.bats)
  - rename: all @test names to match new scenario names exactly (1:1 mapping)
  - remove: redundant `# Scenario:` and `# Example:` comments (info already in test name)
  - add: test for "No PR for current branch: WCF is active"
  - add: test for "No PR for current branch: branch has no upstream"
  - add: `_assert_no_pr_base_outcome` helper -- encapsulates base scenario outcome assertions (status, prompts, browser call); used in all four sub-scenario tests to mirror Gherkin delegation

- [x] update: [tests/sys/uspecs.sh-prompt-uaccept.bats](../../../../../tests/sys/uspecs.sh-prompt-uaccept.bats)
  - rename: all @test names to match new scenario names exactly (1:1 mapping)
  - remove: redundant `# Scenario:` and `# Example:` comments
