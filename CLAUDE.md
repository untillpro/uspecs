# Agents instructions

## General guidelines

- Avoid redirecting stderr to /dev/null (`2>/dev/null`); it silences error messages while the exit code still propagates, making failures hard to diagnose. Suppress output only when the command is genuinely expected to fail, and always provide a clear error message on failure instead.
- Use `tests/run-tests.py [test-folder] [<pattern>]` for tests

<!-- uspecs:begin -->

## Execution instructions

When a request starts with one of the following keywords, you must execute `bash uspecs/u/scripts/uspecs.sh action {keyword}` and follow the instructions provided in the output: upr, uaccept.

When a request starts with one of the keywords below, you must read the corresponding file and follow the rules described there:

- uchange: create a change request following rules from `uspecs/u/actn-uchange.md`
- uarchive, uimpl, usync, udecs, uhow: perform action described in `uspecs/u/actn-{keyword}.md`

Use files from `./uspecs/u` as an initial reference when user mentions uspecs.

<!-- uspecs:end -->
