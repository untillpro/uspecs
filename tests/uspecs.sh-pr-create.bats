#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

@test "pr create succeeds and outputs PR URL" {
    cd "$PROJECT_ROOT"

    git checkout -b pr-create-change
    echo "content" > "$PROJECT_ROOT/new-file.txt"
    git add .
    git commit -q -m "feature commit"

    uspecs pr create --title "Test PR" --body "Test body"
    [ "$status" -eq 0 ]
    [[ "$output" == *"https://github.com/org/repo/pull/42"* ]]
}

@test "pr create passes correct args to gh and body via stdin" {
    cd "$PROJECT_ROOT"

    git checkout -b pr-args-change
    echo "content" > "$PROJECT_ROOT/pr-args-file.txt"
    git add .
    git commit -q -m "pr args commit"

    uspecs pr create --title "Args PR" --body "Expected body"
    [ "$status" -eq 0 ]

    # gh must have received the standard PR creation flags.
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"--repo"* ]]
    [[ "$gh_calls" == *"--base"* ]]
    [[ "$gh_calls" == *"--head"* ]]
    [[ "$gh_calls" == *"--body-file"* ]]

    # Body must have been passed via stdin (--body-file -).
    [ "$(cat "$BATS_TEST_TMPDIR/gh.body")" = "Expected body" ]
}

@test "pr create fails when PR branch already exists" {
    cd "$PROJECT_ROOT"
    _make_change_folder "2601010000-existing-pr"
    git checkout -b existing-pr-change

    # Pre-create the PR branch that changepr would try to create
    git checkout -b "existing-pr-change--pr"
    git checkout existing-pr-change

    uspecs pr create --title "Test PR" --body "Test body"
    [ "$status" -ne 0 ]
    local want="PR branch"
    [[ "$output" =~ $want ]]
}

@test "pr create rolls back pr branch and preserves change branch on failure" {
    cd "$PROJECT_ROOT"
    _make_change_folder "2601010000-rollback"
    git checkout -b rollback-change

    export GH_STUB_FAIL=1
    uspecs pr create --title "Rollback Test" --body "Test body"
    unset GH_STUB_FAIL

    [ "$status" -ne 0 ]
    # pr_branch must be cleaned up locally
    [ -z "$(git -C "$PROJECT_ROOT" branch --list "rollback-change--pr")" ]
    # change_branch must be preserved
    [ -n "$(git -C "$PROJECT_ROOT" branch --list "rollback-change")" ]
}

