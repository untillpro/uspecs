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
# And step from .feature file being verified
# param: value1, value2
```

Rules:

- `feature:` - lowercase feature name matching the .feature file (e.g. `install`)
- `scn:` - prefix followed by scenario name from the .feature file
- Brief disambiguator after scenario name - distinguishes multiple tests from the same scenario
- `# <Step>` comments - quote the relevant `Then`/`And`/`But` steps from the .feature file verbatim
- `# <param>:` comments - resolve `<placeholder>` values from Scenario Outline Examples (use the placeholder name as the comment key, e.g. `# file:`, `# method:`)

Example:

```bash
@test "install: scn: Install stable version: nlia + nlic"
# And <file> is created if it does not exist
# And instructions are injected into <file>
# file: AGENTS.md, CLAUDE.md
```
