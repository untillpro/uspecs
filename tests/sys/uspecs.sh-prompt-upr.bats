#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# Helper: create a change folder with a proper heading for md_read_title.
# Usage: _make_upr_change <folder_name> <title> [issue_url]
_make_upr_change() {
    local folder_name="$1"
    local title="${2:-Test change title}"
    local issue_url="${3:-}"

    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    {
        echo '---'
        echo "registered_at: 2026-01-01T00:00:00Z"
        echo "change_id: $folder_name"
        if [[ -n "$issue_url" ]]; then
            echo "issue_url: $issue_url"
        fi
        echo '---'
        echo ''
        echo "# Change request: $title"
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"

    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "add $folder_name"
}

# Helper: set up a feature branch with a WCF ready for prompt upr.
# Returns with CWD in $PROJECT_ROOT on the feature branch.
_setup_upr_branch() {
    local folder_name="${1:-2601010000-test-change}"
    local title="${2:-Test change title}"
    local issue_url="${3:-}"

    cd "$PROJECT_ROOT"
    git checkout -q -b my-feature
    _make_upr_change "$folder_name" "$title" "$issue_url"
}

# --- PR already exists ---

@test "prompt upr: PR already exists - displays message and opens browser" {
    _setup_upr_branch
    export GH_STUB_PR_EXISTS=1

    uspecs prompt upr
    [ "$status" -eq 0 ]
    [[ "$output" == *"## upr_already_exists"* ]]

    # gh pr view --web was called to open browser
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr view --web"* ]]
}

# --- Successful creation flow ---

@test "prompt upr: successful creation - squash, force-push, open browser, output next steps" {
    _setup_upr_branch

    # Record pre-squash HEAD to verify it appears in the output
    cd "$PROJECT_ROOT"
    local pre_head
    pre_head=$(git rev-parse HEAD)

    uspecs prompt upr
    [ "$status" -eq 0 ]

    # Output contains success prompt with pre_push_head substituted
    [[ "$output" == *"## upr_success"* ]]
    [[ "$output" == *"$pre_head"* ]]

    # gh pr create --web was called
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr create --web"* ]]

    # Branch was squashed: only one commit beyond merge-base
    cd "$PROJECT_ROOT"
    local count
    count=$(git rev-list --count origin/main..HEAD)
    [ "$count" -eq 1 ]
}

@test "prompt upr: successful creation with archived Working Change Folder" {
    cd "$PROJECT_ROOT"
    git checkout -q -b archived-wcf-branch

    # Create archived change folder (simulates post-upr state where folder was already archived)
    local archive_path="$PROJECT_ROOT/uspecs/changes/archive/2601/2601010000-archived-change"
    mkdir -p "$archive_path"
    {
        echo '---'
        echo "registered_at: 2026-01-01T00:00:00Z"
        echo "change_id: 2601010000-archived-change"
        echo "archived_at: 2026-01-01T01:00:00Z"
        echo '---'
        echo ''
        echo '# Change request: Archived change'
    } > "$archive_path/change.md"
    git add .
    git commit -q -m "archived WCF"

    uspecs prompt upr
    [ "$status" -eq 0 ]
    [[ "$output" == *"## upr_success"* ]]
}

# --- pr_title and commit_message with issue_url ---

@test "prompt upr: commit message and PR title include issue reference when issue_url present" {
    _setup_upr_branch "2601010000-issue-change" "Fix the bug" "https://github.com/org/repo/issues/42"

    uspecs prompt upr
    [ "$status" -eq 0 ]
    [[ "$output" == *"## upr_success"* ]]

    # gh pr create was called with title containing issue id
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"[42] Fix the bug"* ]]

    # Commit message contains Closes #42
    cd "$PROJECT_ROOT"
    local msg
    msg=$(git log -1 --format=%B)
    [[ "$msg" == *"Closes #42: Fix the bug"* ]]
    [[ "$msg" == *"See uspecs/changes/2601010000-issue-change/change.md for details"* ]]
}

# --- pr_title and commit_message without issue_url ---

@test "prompt upr: commit message and PR title without issue reference when no issue_url" {
    _setup_upr_branch "2601010000-no-issue" "Add feature"

    uspecs prompt upr
    [ "$status" -eq 0 ]
    [[ "$output" == *"## upr_success"* ]]

    # gh pr create was called with title = change_title only
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"--title Add feature"* ]]

    # Commit message is just title + see_details_line
    cd "$PROJECT_ROOT"
    local msg
    msg=$(git log -1 --format=%B)
    [[ "$msg" == "Add feature"* ]]
    [[ "$msg" == *"See uspecs/changes/2601010000-no-issue/change.md for details"* ]]
    # Should NOT contain "Closes"
    [[ "$msg" != *"Closes"* ]]
}

# --- Edge cases ---

@test "prompt upr: edge - no changes since branching from default branch" {
    cd "$PROJECT_ROOT"
    git checkout -q -b empty-feature

    uspecs prompt upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No changes detected"* ]]
}

@test "prompt upr: edge - no git repository" {
    rm -rf "$PROJECT_ROOT/.git"
    cd "$PROJECT_ROOT"

    uspecs prompt upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No git repository"* ]]
}

@test "prompt upr: edge - working tree has uncommitted changes" {
    _setup_upr_branch
    echo "dirty" > "$PROJECT_ROOT/dirty-file.txt"

    uspecs prompt upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"uncommitted changes"* ]]
}

@test "prompt upr: edge - current branch is the default branch" {
    cd "$PROJECT_ROOT"

    uspecs prompt upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"default branch"* ]]
}

@test "prompt upr: edge - not exactly one Working Change Folder exists (zero)" {
    cd "$PROJECT_ROOT"
    git checkout -q -b no-wcf-branch
    # Make a change outside changes_folder so diff is non-empty
    echo "content" > "$PROJECT_ROOT/some-file.txt"
    git add .
    git commit -q -m "non-change-folder commit"

    uspecs prompt upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No Working Change Folder"* ]]
}

@test "prompt upr: edge - Multiple Working Change Folders exist" {
    cd "$PROJECT_ROOT"
    git checkout -q -b multi-wcf-branch

    # Create two change folders
    _make_upr_change "2601010000-first-change" "First change"
    _make_upr_change "2601010000-second-change" "Second change"

    uspecs prompt upr
    [ "$status" -ne 0 ]

    # Verify error lists both folders
    [[ "${stderr:-}" == *"Multiple Working Change Folders"* ]]
    [[ "${stderr:-}" == *"2601010000-first-change"* ]]
    [[ "${stderr:-}" == *"2601010000-second-change"* ]]
}

@test "prompt upr: edge - change folder has uncompleted todo items" {
    cd "$PROJECT_ROOT"
    git checkout -q -b todo-feature
    local folder_name="2601010000-with-todos"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"

    # Create change.md with uncompleted item
    {
        echo '---'
        echo "registered_at: 2026-01-01T00:00:00Z"
        echo "change_id: $folder_name"
        echo '---'
        echo ''
        echo '# Change request: Has todos'
        echo ''
        echo '- [ ] uncompleted task in change'
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"

    # Create impl.md with uncompleted item
    {
        echo '# Implementation plan'
        echo ''
        echo '- [ ] uncompleted task in impl'
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/impl.md"

    git add .
    git commit -q -m "add folder with todos"

    uspecs prompt upr
    [ "$status" -ne 0 ]

    # Verify detailed error message with file names
    [[ "$output" == *"uncompleted todo item"* ]]
    [[ "$output" == *"change.md"* ]]
    [[ "$output" == *"impl.md"* ]]
    [[ "$output" == *"Complete"* ]]
}
