#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# Subcommand families to cover per marker: one action, one meta, one top-level.
_SUBCOMMANDS=(
    "action uversion"
    "meta options uversion"
    "self-review --type specs --stage A"
)

_assert_guard_fires_for_all_subcommands() {
    local subcmd
    for subcmd in "${_SUBCOMMANDS[@]}"; do
        # shellcheck disable=SC2086
        uspecs $subcmd
        [ "$status" -ne 0 ]
        [[ "${stderr:-}" == *"plugin or skill"* ]]
        [[ "${stderr:-}" == *"project root"* ]]
    done
}

@test "cwd guard: SKILL.md in cwd blocks every subcommand family" {
    cd "$PROJECT_ROOT"
    : > "$PROJECT_ROOT/SKILL.md"

    _assert_guard_fires_for_all_subcommands
}

@test "cwd guard: .claude-plugin/plugin.json in cwd blocks every subcommand family" {
    cd "$PROJECT_ROOT"
    mkdir -p "$PROJECT_ROOT/.claude-plugin"
    : > "$PROJECT_ROOT/.claude-plugin/plugin.json"

    _assert_guard_fires_for_all_subcommands
}

@test "cwd guard: .claude-plugin/marketplace.json in cwd blocks every subcommand family" {
    cd "$PROJECT_ROOT"
    mkdir -p "$PROJECT_ROOT/.claude-plugin"
    : > "$PROJECT_ROOT/.claude-plugin/marketplace.json"

    _assert_guard_fires_for_all_subcommands
}

@test "cwd guard: cwd without markers is unaffected" {
    cd "$PROJECT_ROOT"

    uspecs action uversion
    [ "$status" -eq 0 ]
    [[ "$output" == *"Action: uversion"* ]]
}
