#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# Helper: create a change folder with a proper heading for md_read_title.
# Usage: _make_umergepr_change <folder_name> <title>
# shellcheck disable=SC2120  # Second argument is optional with default
_make_umergepr_change() {
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

# Helper: set up a feature branch with a WCF and upstream ready for action umergepr.
# Returns with CWD in $PROJECT_ROOT on the feature branch.
# shellcheck disable=SC2120  # Arguments are optional with defaults
_setup_umergepr_branch() {
    local folder_name="${1:-2601010000-test-change}"
    local title="${2:-Test change title}"

    cd "$PROJECT_ROOT"
    git checkout -q -b my-feature
    _make_umergepr_change "$folder_name" "$title"

    # Push to origin and set upstream
    git push -q origin my-feature
    git branch --set-upstream-to=origin/my-feature
}

@test "action umergepr: PR not found" {
    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=0

    uspecs action umergepr
    [ "$status" -eq 0 ]
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"umergepr_no_pr"* ]]
    [[ "$output" == *"No open PR found"* ]]
}

@test "action umergepr: PR in OPEN state" {
    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'

    uspecs action umergepr
    [ "$status" -eq 0 ]

    # Verify structured output tags and success message with restore instructions
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"umergepr_success"* ]]
    [[ "$output" == *"PR #42 has been merged successfully"* ]]
    [[ "$output" == *"https://github.com/org/repo/pull/42"* ]]
    [[ "$output" == *"my-feature"* ]]
    [[ "$output" == *"git branch my-feature"* ]]

    # Verify gh pr merge was called with correct flags
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr merge --squash --delete-branch"* ]]
}

@test "action umergepr: PR in OPEN state: Attempt to merge PR fails" {
    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_MERGE_FAIL=1

    uspecs action umergepr
    [ "$status" -eq 0 ]

    # Verify structured output tags and merge failed message
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"umergepr_merge_failed"* ]]
    [[ "$output" == *"Merge of PR #42 failed"* ]]
    [[ "$output" == *"run \`umergepr\` again"* ]]

    # Verify gh pr view --web was called
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr view --web"* ]]
}

@test "action umergepr: PR in OPEN state: WCF is active" {
    cd "$PROJECT_ROOT"
    git checkout -q -b my-feature

    # Create active change folder (not in archive/)
    local folder_name="2601010000-active-change"
    _make_umergepr_change "$folder_name" "Active change"

    # Push to origin and set upstream
    git push -q origin my-feature
    git branch --set-upstream-to=origin/my-feature

    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'

    uspecs action umergepr
    [ "$status" -eq 0 ]

    # After squash merge, we're on default branch and feature branch is deleted
    # The squash merge combines all commits, so individual commit messages are lost
    # Verify WCF was archived by checking the working tree after merge
    local archive_count
    archive_count=$(find "$PROJECT_ROOT/uspecs/changes/archive" -type d -name "*active-change" 2>/dev/null | wc -l)
    [ "$archive_count" -eq 1 ]

    # Verify original folder was removed
    [ ! -d "$PROJECT_ROOT/uspecs/changes/$folder_name" ]

    # Verify structured output tags and success message
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"umergepr_success"* ]]
}

@test "action umergepr: PR in OPEN state: upstream remote exists" {
    cd "$PROJECT_ROOT"

    # Set up upstream bare repo (fork setup)
    local _tmpdir="$BATS_TEST_TMPDIR"
    case "$OSTYPE" in
        msys*|cygwin*) _tmpdir=$(cygpath -m "$_tmpdir") ;;
    esac
    local upstream_repo="$_tmpdir/upstream.git"
    git -c init.defaultBranch=main init -q --bare "$upstream_repo"
    (cd "$upstream_repo" && git symbolic-ref HEAD refs/heads/main)
    git remote add upstream "$upstream_repo"
    git push -q upstream HEAD:main

    # Create feature branch with WCF
    git checkout -q -b my-feature
    _make_umergepr_change "2601010000-upstream-test" "Upstream test"
    git push -q origin my-feature
    git branch --set-upstream-to=origin/my-feature

    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'

    uspecs action umergepr
    [ "$status" -eq 0 ]

    # Verify structured output tags and success message
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"umergepr_success"* ]]
    [[ "$output" == *"PR #42 has been merged successfully"* ]]
    [[ "$output" == *"https://github.com/org/repo/pull/42"* ]]

    # Verify gh pr update-branch was called before merge
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr update-branch"* ]]

    # Verify fetch+ff was attempted
    [[ "$output" == *"Fetching upstream/main"* ]]

    # Verify no divergence warning (ff should succeed)
    [[ "$output" != *"has diverged"* ]]

    # Verify WCF was detected (no warning)
    [[ "$output" != *"WCF not detected"* ]]

    # Verify we are on the default branch and it contains the archived WCF
    local current_branch
    current_branch=$(git -C "$PROJECT_ROOT" symbolic-ref --short HEAD)
    [ "$current_branch" = "main" ]
    local archive_count
    archive_count=$(find "$PROJECT_ROOT/uspecs/changes/archive" -type d -name "*-upstream-test" 2>/dev/null | wc -l)
    [ "$archive_count" -eq 1 ]
}


@test "action umergepr: PR not in OPEN state" {
    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"MERGED","url":"https://github.com/org/repo/pull/42"}'

    uspecs action umergepr
    [ "$status" -eq 0 ]

    # Verify structured output tags and not_open message
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"umergepr_not_open"* ]]
    [[ "$output" == *"PR #42 is in MERGED state"* ]]
    [[ "$output" == *"git branch my-feature"* ]]

    # Verify gh pr view --web was called
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr view --web"* ]]
}

# Git validations#Project inside Git working tree
@test "action umergepr: Validation rejects, no git repository" {
    rm -rf "$PROJECT_ROOT/.git"
    cd "$PROJECT_ROOT"

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No git repository"* ]]
}

# Git validations#Git working tree is clean
@test "action umergepr: Validation rejects, working tree has uncommitted changes" {
    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch
    echo "uncommitted" > "$PROJECT_ROOT/dirty.txt"

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"uncommitted changes"* ]]
}

# Git validations#Git working tree is clean
@test "action umergepr: Validation rejects, current branch is the default branch" {
    cd "$PROJECT_ROOT"
    git checkout -q main

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Current branch is the default branch"* ]]
}

@test "action umergepr: Validation rejects, current branch has no upstream" {
    cd "$PROJECT_ROOT"
    git checkout -q -b no-upstream-branch
    _make_umergepr_change "2601010000-no-upstream" "No upstream"
    # Do NOT set upstream

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"has no upstream"* ]]
}

# Change Folder validations#Exactly one Working Change Folder
@test "action umergepr: Validation rejects, No Working Change Folder exists" {
    cd "$PROJECT_ROOT"
    git checkout -q -b empty-branch
    # Create a commit without any change folder
    echo "test" > test.txt
    git add test.txt
    git commit -q -m "test commit"
    git push -q origin empty-branch
    git branch --set-upstream-to=origin/empty-branch

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No Working Change Folder"* ]]
}

@test "action umergepr: Validation rejects, Multiple Working Change Folder exists" {
    cd "$PROJECT_ROOT"
    git checkout -q -b multi-wcf-branch
    _make_umergepr_change "2601010000-first-change" "First change"
    _make_umergepr_change "2601010000-second-change" "Second change"
    git push -q origin multi-wcf-branch
    git branch --set-upstream-to=origin/multi-wcf-branch

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Multiple Working Change Folders"* ]]
}
