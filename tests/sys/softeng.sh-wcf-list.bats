#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

@test "change list-wcf: no git repo: returns all non-archive subdirs, empty returns nothing" {
    # Uses the cheap default setup() -- no git repo initialised.

    # Empty changes folder
    uspecs change list-wcf
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    # Non-archive subdirs returned, archive excluded
    mkdir -p "$PROJECT_ROOT/uspecs/changes/alpha-change"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/beta-change"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/archive/2601/archived-one"

    uspecs change list-wcf
    [ "$status" -eq 0 ]
    local lines
    lines=$(printf '%s\n' "$output" | grep -c '.')
    [ "$lines" -eq 2 ]
    [[ "$output" == *"alpha-change"* ]]
    [[ "$output" == *"beta-change"* ]]
    [[ "$output" != *"archive"* ]]
}

@test "change list-wcf: git repo: committed, untracked, staged, archived" {
    _setup_git_origin

    # Folder on main (before branching) should not appear
    _make_change_folder "2601010000-on-main"
    git push -q origin main
    uspecs change list-wcf
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    git checkout -q -b feature-branch

    # One committed folder
    _make_change_folder "2601010000-my-change"
    uspecs change list-wcf
    [ "$status" -eq 0 ]
    [ "$output" = "2601010000-my-change" ]
    [[ "$output" != *"on-main"* ]]

    # Multiple committed folders, sorted
    _make_change_folder "2601010000-zebra"
    _make_change_folder "2601010000-alpha"
    uspecs change list-wcf
    [ "$status" -eq 0 ]
    local first_line last_line
    first_line=$(printf '%s\n' "$output" | head -1)
    last_line=$(printf '%s\n' "$output" | tail -1)
    [ "$first_line" = "2601010000-alpha" ]
    [ "$last_line" = "2601010000-zebra" ]

    # Archived change folder detected
    mkdir -p "$PROJECT_ROOT/uspecs/changes/archive/2601/2601010000-old"
    echo "test" > "$PROJECT_ROOT/uspecs/changes/archive/2601/2601010000-old/change.md"
    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "add archived"
    uspecs change list-wcf
    [ "$status" -eq 0 ]
    [[ "$output" == *"archive/2601/2601010000-old"* ]]

    # Untracked folder
    mkdir -p "$PROJECT_ROOT/uspecs/changes/2601010000-untracked"
    echo "test" > "$PROJECT_ROOT/uspecs/changes/2601010000-untracked/change.md"
    uspecs change list-wcf
    [ "$status" -eq 0 ]
    [[ "$output" == *"2601010000-untracked"* ]]

    # Staged but uncommitted folder
    rm -rf "$PROJECT_ROOT/uspecs/changes/2601010000-untracked"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/2601010000-staged"
    echo "test" > "$PROJECT_ROOT/uspecs/changes/2601010000-staged/change.md"
    git -C "$PROJECT_ROOT" add .
    uspecs change list-wcf
    [ "$status" -eq 0 ]
    [[ "$output" == *"2601010000-staged"* ]]
}
