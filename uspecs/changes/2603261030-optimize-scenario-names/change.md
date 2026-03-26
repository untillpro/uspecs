---
registered_at: 2026-03-26T10:30:53Z
change_id: 2603261030-optimize-scenario-names
baseline: 4c2d741d0c72f944453a233b2e9b4679dfb6c25d
---

# Change request: Optimize scenario names

## Why

Scenario names in feature files and test names in .bats files are inconsistent and do not clearly convey test purpose. The `upr.feature` file demonstrates a good naming pattern where scenario names describe specific conditions and outcomes, and test names in `uspecs.sh-prompt-upr.bats` mirror those scenario names to make traceability obvious.

## What

Optimize scenario names across feature files and align test names to match scenario purposes:

Feature file scenario names:

- Rename scenarios in `uchange.feature` and shared validation features to follow the descriptive style used in `upr.feature`
- Scenario names should reflect specific conditions and outcomes, not just commands

Test names in .bats files:

- Update test names in `uspecs.sh-change-new.bats` to use names that match or clearly reference the corresponding scenario from the feature file
