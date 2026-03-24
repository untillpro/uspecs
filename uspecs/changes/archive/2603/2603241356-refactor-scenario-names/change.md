---
registered_at: 2026-03-24T11:31:10Z
change_id: 2603241131-refactor-scenario-names
baseline: 0a34e1df87fb79757900d48b2db4c667c81f4a79
archived_at: 2026-03-24T13:56:42Z
---

# Change request: Refactor scenario names

## Why

Scenario names in upr.feature and uaccept.feature are overly long and some scenarios embed multiple
conditional behaviors ("if active", "if not already") that are better expressed as separate focused
scenarios following the delegation pattern already used in uaccept.feature.

## What

Shorten scenario names and split conditional steps into focused scenarios:

- In upr.feature:
  - Shorten "Create pull request, current branch has a PR associated with it" -> "PR exists for current branch"
  - Shorten "Create pull request, current branch does not have a PR associated with it" -> "No PR for current branch" (base scenario)
  - Split out "No PR for current branch: WCF is active" -- delegates to base
  - Split out "No PR for current branch: branch has no upstream" -- delegates to base
  - Shorten "pr_title and commit_message include issue reference when available" -> "No PR for current branch: PR title and commit message"

- In uaccept.feature:
  - Shorten "PR in OPEN state: Active Working Change Folder exists" -> "PR in OPEN state: WCF is active"
  - Shorten "PR is not in OPEN state" -> "PR not in OPEN state"

- In tests:
  - Align BATS test names and comments with new scenario names
  - Add tests for the two new split scenarios (WCF active and no upstream)
