---
name: bats
description: Use this skill when authoring or reviewing any `*.bats` file (Bats test).
user-invocable: false
---

# Bats tests

- Never use trap in bats tests
- Do not run all tests for tests/sys, tests/e2e unless explicitly requested by the user, run only tests relevant to the user request

## Test naming

When the test corresponds to a .feature scenario, use the following format (mandatory - do not invent alternate naming schemes):

```bash
@test "feature: scn: Scenario Name: brief disambiguator"
# Then step from .feature file being verified
# And separate step from .feature file being verified
# | param1 | param2 |
# | value1 | value2 |
```

Rules:

- `feature:` - lowercase feature name matching the .feature file (e.g. `install`)
- `scn:` - prefix followed by scenario (or scenario outline) name from the .feature file
- Brief disambiguator after scenario name - distinguishes multiple tests from the same scenario; for Scenario Outline rows, identify the row (e.g. by the distinguishing column value)
- `# <Step>` comments label code lines, not the test as a whole - each comment quotes one Gherkin step (`Given`, `When`, `Then`, `And`, `But`) verbatim from the .feature file and sits immediately above the line(s) that realize it:
    - `Given` -> the setup line (helper call, fixture creation, branch checkout, etc.) that establishes the precondition
    - `When` -> the action line under test (the command, `run`, or function invocation that triggers the behavior)
    - `Then` / `And` / `But` -> the assertion line(s) that verify the outcome
- Do not add a step comment that merely restates what the Examples table inputs already show (e.g. a `Given` above a bare `run` whose argument is the input from the row, or a `When` above a `run` whose only parameter comes straight from a row column); the test name and the two-line table comment already pin that information. Add the comment only when it labels something the code actually does beyond echoing the row.
- Do not combine, summarize, or paraphrase multiple feature steps into one comment
- For Scenario Outline step comments, keep the step text byte-for-byte verbatim with its `<placeholders>` intact, and immediately below add one `# placeholder_name = value` line per placeholder that appears in the step, using the value from the row in the two-line table comment above. Do not substitute placeholders inline, and do not add free-form paraphrase lines (the `placeholder_name = value` mapping replaces them):

    ```bash
    # | branch               | type | branch_outcome |
    # | a non-default branch | fix  | is not created |
    ...
    # And Git branch <branch_outcome>
    # branch_outcome = is not created
    [[ "$output" != *"git checkout -b"* ]]
    ```

- If one line realizes multiple feature steps, stack the separate verbatim feature-step comments immediately above that line
- Tests without a matching `.feature` scenario must not use `scn:` in the test name
- For Scenario Outline examples, copy the Examples table header and the specific row being verified as exactly two comment lines (one for header, one for the row) immediately near that case
- The two table comment lines must be byte-for-byte verbatim copies from the .feature file - preserve leading/trailing pipes, every column-alignment whitespace, and every character - so `grep`/`rg` finds the same row text in both files
- Never reflow a table row across multiple comment lines, drop the pipes, or rewrite the row in a different layout (e.g. `# row: target -> result`)
- When one Bats test covers multiple Scenario Outline rows, repeat the two-line table comment for each row near that row's command/assertion block

Example - Scenario Outline, step comments label code lines (`Given` above setup, `When` above the action, `Then` above the assertion; each step's placeholders are resolved via `name = value` lines):

```bash
@test "uchange: scn: Type flag: feat" {
    # | branch             | type | expected_branch_prefix |
    # | the default branch | feat | feat/                  |
    # Given Engineer is on <branch>
    # branch = the default branch
    _setup_git_repo
    # When Engineer invokes uchange action with --type <type>
    # type = feat
    uspecs action uchange --kebab-name my-change --type feat
    # Then a branch is created with prefix <expected_branch_prefix>
    # expected_branch_prefix = feat/
    [[ "$(git branch --show-current)" == feat/* ]]
}
```

When the test is a pure stdin -> stdout function call with no setup and the action line is just the row input, drop the `Given`/`When` and keep only the `Then` with its `name = value` mapping:

```bash
@test "upr: scn: PR body link handling: mailto: in paragraph" {
    # | link_target                   | link_context           | rendered_link      |
    # | mailto:user@example.com       | regular paragraph      | the link unchanged |
    # Then pr_body renders the link as <rendered_link>
    # rendered_link = the link unchanged
    run -0 md_defang_relative_link <<< '[mail](mailto:user@example.com)'
    [ "$output" = '[mail](mailto:user@example.com)' ]
}
```

Scenario Outline with multiple rows in one Bats test - repeat the two-line table comment and the `name = value` mapping for each row block:

```bash
@test "uchange: scn: Issue URL: branch naming" {
    # | issue_url                               | change_name | branch_name   |
    # | https://github.com/owner/repo/issues/42 | my-feature  | 42-my-feature |
    run_action --issue-url "https://github.com/owner/repo/issues/42" --name my-feature
    # Then Git branch is created with name <branch_name>
    # branch_name = 42-my-feature
    [[ "$output" == *"git checkout -b 42-my-feature"* ]]

    # | issue_url                                | change_name | branch_name      |
    # | https://jira.example.com/browse/PROJ-123 | fix-bug     | PROJ-123-fix-bug |
    run_action --issue-url "https://jira.example.com/browse/PROJ-123" --name fix-bug
    # Then Git branch is created with name <branch_name>
    # branch_name = PROJ-123-fix-bug
    [[ "$output" == *"git checkout -b PROJ-123-fix-bug"* ]]
}
```
