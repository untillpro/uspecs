#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

@test "change new creates change folder and change.md" {
    cd "$PROJECT_ROOT"
    uspecs change new my-change
    [ "$status" -eq 0 ]
    [[ "$output" == uspecs/changes/[0-9]*-my-change ]]
    [ -d "$PROJECT_ROOT/$output" ]
    [ -f "$PROJECT_ROOT/$output/change.md" ]
    grep -q "change_id:.*my-change" "$PROJECT_ROOT/$output/change.md"
}

@test "change new --branch creates git branch" {
    cd "$PROJECT_ROOT"
    uspecs change new my-feature --branch
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/my-feature
}

@test "change new with unknown flag fails" {
    cd "$PROJECT_ROOT"
    uspecs change new my-change --unknown-flag
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown"* ]]
}

@test "change new with missing change-name fails" {
    cd "$PROJECT_ROOT"
    uspecs change new
    [ "$status" -ne 0 ]
    [[ "$output" == *"change-name is required"* ]]
}

@test "change new with invalid change-name format fails" {
    cd "$PROJECT_ROOT"
    uspecs change new "Invalid_Name"
    [ "$status" -ne 0 ]
    [[ "$output" == *"kebab-case"* ]]
}

