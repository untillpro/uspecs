---
name: bats
description: Use this skill when authoring or reviewing any `*.bats` file (Bats test).
user-invocable: false
---

# Bats tests

- Never use trap in bats tests
- Do not run all tests for tests/sys, tests/e2e unless explicitly requested by the user, run only tests relevant to the user request

## Test naming

When the test corresponds to a .feature scenario, use the following format:

```bash
@test "feature: scn: Scenario Name: brief disambiguator"
# Then step from .feature file being verified
# And separate step from .feature file being verified
# | param1 | param2 |
# | value1 | value2 |
```

Rules:

- `feature:` - lowercase feature name matching the .feature file (e.g. `install`)
- `scn:` - prefix followed by scenario name from the .feature file
- Brief disambiguator after scenario name - distinguishes multiple tests from the same scenario
- `# <Step>` comments - for every `Then`, `And`, and `But` step verified by the test, add a separate comment that quotes that single step verbatim from the .feature file
- Do not combine, summarize, or paraphrase multiple feature steps into one comment
- Place each feature-step comment immediately above the assertion or command block that verifies it
- If one assertion or block verifies multiple feature steps, stack the separate verbatim feature-step comments immediately above that block
- Tests without a matching `.feature` scenario must not use `scn:` in the test name
- For Scenario Outline examples, copy the Examples table header and the specific row being verified as two comment lines immediately near that case
- When one Bats test covers multiple Scenario Outline rows, repeat the two-line table comment for each row near that row's command/assertion block

Example:

```bash
@test "feature: scn: Scenario Outline Name: row disambiguator"
# And <file> is created if it does not exist
# And instructions are injected into <file>
# | file      | method      |
# | AGENTS.md | nlia + nlic |
```

Scenario Outline with multiple rows in one Bats test:

```bash
@test "uchange: scn: Issue URL: branch naming" {
    # | issue_url                               | change_name | branch_name   |
    # | https://github.com/owner/repo/issues/42 | my-feature  | 42-my-feature |
    run_action --issue-url "https://github.com/owner/repo/issues/42" --name my-feature
    # Then Git branch is created with name <branch_name>
    [[ "$output" == *"git checkout -b 42-my-feature"* ]]

    # | issue_url                                | change_name | branch_name      |
    # | https://jira.example.com/browse/PROJ-123 | fix-bug     | PROJ-123-fix-bug |
    run_action --issue-url "https://jira.example.com/browse/PROJ-123" --name fix-bug
    # Then Git branch is created with name <branch_name>
    [[ "$output" == *"git checkout -b PROJ-123-fix-bug"* ]]
}
```
