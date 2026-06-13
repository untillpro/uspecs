#!/usr/bin/env bats
set -Eeuo pipefail

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
    source "$REPO_ROOT/bin/_lib/utils.sh"
}

# ---------------------------------------------------------------------------
# shell_quote_args
# ---------------------------------------------------------------------------

@test "shell_quote_args: basic argument handling" {
    # No arguments returns empty
    run shell_quote_args
    [ "$status" -eq 0 ]
    [ "$output" = "" ]

    # Single simple argument includes leading space
    run shell_quote_args "foo"
    [ "$status" -eq 0 ]
    [ "$output" = " foo" ]

    # Multiple simple arguments are space-separated
    run shell_quote_args "foo" "bar" "baz"
    [ "$status" -eq 0 ]
    [ "$output" = " foo bar baz" ]
}

@test "shell_quote_args: quoting and escaping" {
    # Argument with spaces is escaped
    run shell_quote_args "dir with space"
    [ "$status" -eq 0 ]
    [ "$output" = " dir\\ with\\ space" ]

    # Mixed simple and quoted arguments
    run shell_quote_args "--change-folder" "uspecs/changes/dir with space" "--no-self-review"
    [ "$status" -eq 0 ]
    [ "$output" = " --change-folder uspecs/changes/dir\\ with\\ space --no-self-review" ]

    # Special characters are properly escaped
    run shell_quote_args "arg with \$var" "arg'with'quotes" 'arg"with"doublequotes'
    [ "$status" -eq 0 ]
    # printf %q quotes $ and both quote styles
    [[ "$output" == *\$* ]]
    [[ "$output" == *\'* ]]
}

@test "shell_quote_args: re-invocation pattern for uimpl" {
    # Leading space enables direct concatenation
    local cmd="bash script.sh action"
    local args
    args=$(shell_quote_args "--option" "value")
    local full_cmd="${cmd}${args}"
    [ "$full_cmd" = "bash script.sh action --option value" ]

    # Whitespace preservation for copy/paste re-execution
    local softeng_sh="/path/to/softeng.sh"
    local original_args
    original_args=$(shell_quote_args "--change-folder" "uspecs/changes/dir with space" "--no-self-review")
    local reinvoke_cmd="bash \"$softeng_sh\" action uimpl${original_args}"
    [[ "$reinvoke_cmd" == *"dir\\ with\\ space"* ]]
}
