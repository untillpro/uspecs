#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

@test "pr preflight succeeds on valid change branch" {
    cd "$PROJECT_ROOT"

    # Commit a change folder with no uncompleted items onto main.
    mkdir -p "$PROJECT_ROOT/uspecs/changes/2601010000-preflight"
    printf '%s\n' \
        '---' \
        'registered_at: 2026-01-01T00:00:00Z' \
        'change_id: 2601010000-preflight' \
        '---' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-preflight/change.md"
    git add .
    git commit -q -m "add change"

    # Must be on a non-default branch that does not end with --pr.
    git checkout -b feature-branch

    uspecs pr preflight --change-folder "$PROJECT_ROOT/uspecs/changes/2601010000-preflight"
    [ "$status" -eq 0 ]
    local want
    want="change_branch=feature-branch"
    [[ "$output" =~ $want ]]
    want="default_branch=main"
    [[ "$output" =~ $want ]]
}

@test "pr preflight fails when not in a git repository" {
    cd "$PROJECT_ROOT"
    _make_change_folder "2601010000-nogit"

    # cd to a directory outside any git repo
    local nogit_dir
    nogit_dir="$(dirname "$PROJECT_ROOT")/nogit"
    mkdir -p "$nogit_dir"
    cd "$nogit_dir"

    uspecs pr preflight --change-folder "$PROJECT_ROOT/uspecs/changes/2601010000-nogit"
    [ "$status" -ne 0 ]
    local want="No git repository found"
    [[ "$output" =~ $want ]]
}

@test "pr preflight fails with uncommitted changes" {
    cd "$PROJECT_ROOT"
    _make_change_folder "2601010000-uncommitted"
    git checkout -b feature-uncommitted

    # Create an untracked file to dirty the working tree
    echo "dirty" > "$PROJECT_ROOT/dirty.txt"

    uspecs pr preflight --change-folder "$PROJECT_ROOT/uspecs/changes/2601010000-uncommitted"
    [ "$status" -ne 0 ]
    local want="uncommitted changes"
    [[ "$output" =~ $want ]]
}

@test "pr preflight fails when on default branch" {
    cd "$PROJECT_ROOT"
    _make_change_folder "2601010000-defaultbranch"
    # Stay on main (the default branch)

    uspecs pr preflight --change-folder "$PROJECT_ROOT/uspecs/changes/2601010000-defaultbranch"
    [ "$status" -ne 0 ]
    local want="is the default branch"
    [[ "$output" =~ $want ]]
}

@test "pr preflight fails when branch ends with --pr" {
    cd "$PROJECT_ROOT"
    _make_change_folder "2601010000-prbase"
    git checkout -b feature-thing--pr

    uspecs pr preflight --change-folder "$PROJECT_ROOT/uspecs/changes/2601010000-prbase"
    [ "$status" -ne 0 ]
    local want="ends with '--pr'"
    [[ "$output" =~ $want ]]
}

@test "pr preflight fails with uncompleted todo items" {
    cd "$PROJECT_ROOT"

    # Create change folder with an uncompleted checkbox item
    mkdir -p "$PROJECT_ROOT/uspecs/changes/2601010000-todos"
    printf '%s\n' \
        '---' \
        'registered_at: 2026-01-01T00:00:00Z' \
        'change_id: 2601010000-todos' \
        '---' \
        '' \
        '- [ ] uncompleted item' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-todos/change.md"
    git add .
    git commit -q -m "add todos change"
    git checkout -b feature-todos

    uspecs pr preflight --change-folder "$PROJECT_ROOT/uspecs/changes/2601010000-todos"
    [ "$status" -ne 0 ]
    local want="Cannot create PR"
    [[ "$output" =~ $want ]]
}

@test "pr preflight reports merge conflict" {
    cd "$PROJECT_ROOT"

    # Set up a file that will be modified on both branches
    echo "base content" > "$PROJECT_ROOT/conflict-file.txt"
    git add .
    git commit -q -m "add conflict-file"
    git push -q origin main

    # Create feature branch and make a conflicting change
    git checkout -b conflict-change
    mkdir -p "$PROJECT_ROOT/uspecs/changes/2601010000-conflict"
    printf '%s\n' \
        '---' \
        'registered_at: 2026-01-01T00:00:00Z' \
        'change_id: 2601010000-conflict' \
        '---' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-conflict/change.md"
    echo "feature content" > "$PROJECT_ROOT/conflict-file.txt"
    git add .
    git commit -q -m "feature: diverge conflict-file"

    # Push a different change on origin/main to create a real conflict
    git checkout main
    echo "origin content" > "$PROJECT_ROOT/conflict-file.txt"
    git add .
    git commit -q -m "origin: diverge conflict-file"
    git push -q origin main

    git checkout conflict-change

    # Merge during preflight will fail due to conflict
    uspecs pr preflight --change-folder "$PROJECT_ROOT/uspecs/changes/2601010000-conflict"
    [ "$status" -ne 0 ]
}

