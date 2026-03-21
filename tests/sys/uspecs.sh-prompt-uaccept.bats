#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# Helper: create a change folder with a proper heading for md_read_title.
# Usage: _make_uaccept_change <folder_name> <title>
# shellcheck disable=SC2120  # Second argument is optional with default
_make_uaccept_change() {
    local folder_name="$1"
    local title="${2:-Test change title}"

    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    {
        echo '---'
        echo "registered_at: 2026-01-01T00:00:00Z"
        echo "change_id: $folder_name"
        echo '---'
        echo ''
        echo "# Change request: $title"
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"

    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "add $folder_name"
}

# Helper: set up a feature branch with a WCF and upstream ready for prompt uaccept.
# Returns with CWD in $PROJECT_ROOT on the feature branch.
# shellcheck disable=SC2120  # Arguments are optional with defaults
_setup_uaccept_branch() {
    local folder_name="${1:-2601010000-test-change}"
    local title="${2:-Test change title}"

    cd "$PROJECT_ROOT"
    git checkout -q -b my-feature
    _make_uaccept_change "$folder_name" "$title"

    # Push to origin and set upstream
    git push -q origin my-feature
    git branch --set-upstream-to=origin/my-feature
}

# Scenario: PR not found
@test "prompt uaccept: PR not found" {
    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_uaccept_branch
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=0

    uspecs prompt uaccept
    [ "$status" -eq 0 ]
    [[ "$output" == *"## uaccept_no_pr"* ]]
    [[ "$output" == *"No open PR found"* ]]
}

# Scenario: PR in OPEN state
@test "prompt uaccept: PR in OPEN state - merge succeeds" {
    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_uaccept_branch
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'

    uspecs prompt uaccept
    [ "$status" -eq 0 ]

    # Verify success message
    [[ "$output" == *"## uaccept_success"* ]]
    [[ "$output" == *"PR #42 has been merged successfully"* ]]
    [[ "$output" == *"my-feature"* ]]

    # Verify gh pr merge was called with correct flags
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr merge --squash --delete-branch"* ]]
}

# Scenario: PR in OPEN state: Attempt to merge PR fails
@test "prompt uaccept: PR in OPEN state - merge fails" {
    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_uaccept_branch
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_MERGE_FAIL=1

    uspecs prompt uaccept
    [ "$status" -eq 0 ]
    
    # Verify merge failed message
    [[ "$output" == *"## uaccept_merge_failed"* ]]
    [[ "$output" == *"Merge of PR #42 failed"* ]]
    [[ "$output" == *"run \`uaccept\` again"* ]]

    # Verify gh pr view --web was called
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr view --web"* ]]
}

# Scenario: PR in OPEN state: Active Working Change Folder exists
@test "prompt uaccept: PR in OPEN state - active WCF is archived" {
    cd "$PROJECT_ROOT"
    git checkout -q -b my-feature

    # Create active change folder (not in archive/)
    local folder_name="2601010000-active-change"
    _make_uaccept_change "$folder_name" "Active change"

    # Push to origin and set upstream
    git push -q origin my-feature
    git branch --set-upstream-to=origin/my-feature

    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'

    uspecs prompt uaccept
    [ "$status" -eq 0 ]

    # After squash merge, we're on default branch and feature branch is deleted
    # The squash merge combines all commits, so individual commit messages are lost
    # Verify WCF was archived by checking the working tree after merge
    local archive_count
    archive_count=$(find "$PROJECT_ROOT/uspecs/changes/archive" -type d -name "*active-change" 2>/dev/null | wc -l)
    [ "$archive_count" -eq 1 ]

    # Verify original folder was removed
    [ ! -d "$PROJECT_ROOT/uspecs/changes/$folder_name" ]

    # Verify success message
    [[ "$output" == *"## uaccept_success"* ]]
}

# Scenario: PR is not in OPEN state
@test "prompt uaccept: PR is not in OPEN state" {
    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_uaccept_branch
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"MERGED","url":"https://github.com/org/repo/pull/42"}'

    uspecs prompt uaccept
    [ "$status" -eq 0 ]
    
    # Verify not_open message
    [[ "$output" == *"## uaccept_not_open"* ]]
    [[ "$output" == *"PR #42 is in MERGED state"* ]]
    [[ "$output" == *"git branch my-feature"* ]]

    # Verify gh pr view --web was called
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr view --web"* ]]
}

# Scenario Outline: Validation rejects invalid state
# Example: no git repository
@test "prompt uaccept: Validation rejects, no git repository" {
    rm -rf "$PROJECT_ROOT/.git"
    cd "$PROJECT_ROOT"

    uspecs prompt uaccept
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No git repository"* ]]
}

# Scenario Outline: Validation rejects invalid state
# Example: working tree has uncommitted changes
@test "prompt uaccept: Validation rejects, working tree has uncommitted changes" {
    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_uaccept_branch
    echo "uncommitted" > "$PROJECT_ROOT/dirty.txt"

    uspecs prompt uaccept
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"uncommitted changes"* ]]
}

# Scenario Outline: Validation rejects invalid state
# Example: current branch is the default branch
@test "prompt uaccept: Validation rejects, current branch is the default branch" {
    cd "$PROJECT_ROOT"
    git checkout -q main

    uspecs prompt uaccept
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Current branch is the default branch"* ]]
}

# Scenario Outline: Validation rejects invalid state
# Example: current branch has no upstream
@test "prompt uaccept: Validation rejects, current branch has no upstream" {
    cd "$PROJECT_ROOT"
    git checkout -q -b no-upstream-branch
    _make_uaccept_change "2601010000-no-upstream" "No upstream"
    # Do NOT set upstream

    uspecs prompt uaccept
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"has no upstream"* ]]
}

# Scenario Outline: Validation rejects invalid state
# Example: not exactly one Working Change Folder exists
@test "prompt uaccept: Validation rejects, No Working Change Folder exists" {
    cd "$PROJECT_ROOT"
    git checkout -q -b empty-branch
    # Create a commit without any change folder
    echo "test" > test.txt
    git add test.txt
    git commit -q -m "test commit"
    git push -q origin empty-branch
    git branch --set-upstream-to=origin/empty-branch

    uspecs prompt uaccept
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No Working Change Folder"* ]]
}

# Scenario Outline: Validation rejects invalid state
# Example: Multiple Working Change Folders exist
@test "prompt uaccept: Validation rejects, Multiple Working Change Folder exists" {
    cd "$PROJECT_ROOT"
    git checkout -q -b multi-wcf-branch
    _make_uaccept_change "2601010000-first-change" "First change"
    _make_uaccept_change "2601010000-second-change" "Second change"
    git push -q origin multi-wcf-branch
    git branch --set-upstream-to=origin/multi-wcf-branch

    uspecs prompt uaccept
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Multiple Working Change Folders"* ]]
}
