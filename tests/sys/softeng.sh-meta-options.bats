#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

_actions() {
    python3 "$REPO_ROOT/tests/sys/parse-softeng-action-options.py" "$PROJECT_ROOT/bin/softeng.sh" |
        awk -F '\t' '{ print $1 }'
}

_extract_reported_flags() {
    local flags=""
    flags=$(printf '%s\n' "$1" | grep -Eo -- '-{1,2}[[:alnum:]][[:alnum:]-]*' || :)
    printf '%s\n' "$flags" | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//'
}

_parser_flags_for_action() {
    local action="$1"
    python3 "$REPO_ROOT/tests/sys/parse-softeng-action-options.py" "$PROJECT_ROOT/bin/softeng.sh" "$action" |
        awk -F '\t' '{ print $2 }'
}

@test "meta options: every dispatched action prints options" {
    cd "$PROJECT_ROOT"

    local action
    while IFS= read -r action; do
        uspecs meta options "$action"
        [ "$status" -eq 0 ]
        [[ "$output" == Options:* ]]
    done < <(_actions)
}

@test "meta options: unknown action fails clearly" {
    cd "$PROJECT_ROOT"

    uspecs meta options unknown-action
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"unknown-action"* ]]
}

@test "meta options: action tables match parser arms" {
    cd "$PROJECT_ROOT"

    local action reported parsed
    while IFS= read -r action; do
        uspecs meta options "$action"
        [ "$status" -eq 0 ]

        reported=$(_extract_reported_flags "$output")
        parsed=$(_parser_flags_for_action "$action")

        if [ "$reported" != "$parsed" ]; then
            {
                echo "Option mismatch for $action"
                echo "reported: $reported"
                echo "parsed:   $parsed"
            } >&2
            return 1
        fi
    done < <(_actions)
}
