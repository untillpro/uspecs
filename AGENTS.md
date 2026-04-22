# Agents instructions

## General guidelines

- Avoid redirecting stderr to /dev/null (`2>/dev/null`); it silences error messages while the exit code still propagates, making failures hard to diagnose. Suppress output only when the command is genuinely expected to fail, and always provide a clear error message on failure instead.
- Use `tests/run-tests.py [test-folder] [<pattern>]` to run tests
- Never commit or push changes unless explicitly requested

<!-- uspecs:begin -->

## Execution instructions

- When user input starts with {action} [options] {other-input} like `uchange --no-impl here is some prompt` then
  - run `bash uspecs/u/scripts/softeng.sh action {action} {options}` and follow the instructions in the output how to process {other-input}
    - Do not pass {other-input} verbatim to the command
  - Available commands: upr, umergepr, uimpl, uarchive, usync
  - For uchange
    - {other-input} contains description of change request
    - Determine `kebab-name` from the {other-input}: kebab-case, max 40 chars (ideal 15-30), descriptive, safe to use as a git branch name. Should be passed as --kebab-name option to the command, for example `uchange --kebab-name add-user-authentication`
    - If {other-input} contains URL add --issue-url {URL} option to the command, for example `uchange --issue-url https://example.com`
    - If the user asks to derive specifications from the codebase, add --specs option to the command

<!-- uspecs:end -->
