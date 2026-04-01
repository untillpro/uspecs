# Agents instructions

## General guidelines

- Avoid redirecting stderr to /dev/null (`2>/dev/null`); it silences error messages while the exit code still propagates, making failures hard to diagnose. Suppress output only when the command is genuinely expected to fail, and always provide a clear error message on failure instead.
- Use `tests/run-tests.py [test-folder] [<pattern>]` for tests
- Never commit or push changes unless explicitly requested
- Never use trap in bats tests

## Bats test naming

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

<!-- uspecs:begin -->

## Execution instructions

When a request starts with one of the following keywords, you must execute `bash uspecs/u/scripts/softeng.sh action {keyword}` and follow the instructions provided in the output: upr, umergepr.

When a request starts with one of the keywords below, you must read the corresponding file and follow the rules described there:

- uchange: create a change request following rules from `uspecs/u/actn-uchange.md`
- uarchive, uimpl, usync, udecs, uhow: perform action described in `uspecs/u/actn-{keyword}.md`

Use files from `./uspecs/u` as an initial reference when user mentions uspecs.

<!-- uspecs:end -->
