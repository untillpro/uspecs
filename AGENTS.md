# Agents instructions

## General guidelines

- Answer concisely unless explicitly asked for more detail, prefer short examples over long explanations
- Avoid redirecting stderr to /dev/null (`2>/dev/null`); it silences error messages while the exit code still propagates, making failures hard to diagnose. Suppress output only when the command is genuinely expected to fail, and always provide a clear error message on failure instead
- Do not run tests unless explicitly requested
- Use `tests/run-tests.py [test-folder] [<pattern>]` to run tests
- Never commit or push changes unless explicitly requested

<!-- uspecs:begin -->

## Execution instructions

- When user input starts with `uclarify [options] {other-input}` then
  - read `scripts/templates/actions/uclarify.md` and follow its instructions, treating `{other-input}` as the clarification input
  - Do not run `bin/softeng.sh` for this action
- When user input starts with `uchange [options] {other-input}` then
  - read the `raw_text` block in `scripts/templates/actions/uchange.yaml` and follow its instructions, treating `{other-input}` as `{description}` and `{{dispatch}}` as `run bash bin/softeng.sh action uchange {options}`
- When user input starts with {action} [options] {other-input} like `upr --no-push` then
  - run `bash bin/softeng.sh action {action} {options}` and follow the instructions in the output how to process {other-input}
    - Do not pass {other-input} verbatim to the command
  - Available commands: upr, umergepr, uimpl, uarchive, usync, uversion

<!-- uspecs:end -->
