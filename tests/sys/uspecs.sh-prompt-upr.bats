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

# Helper: set up a feature branch with a WCF ready for action upr.
# Returns with CWD in $PROJECT_ROOT on the feature branch.
_setup_upr_branch() {
    local folder_name="${1:-2601010000-test-change}"
    local title="${2:-Test change title}"
    local issue_url="${3:-}"

    cd "$PROJECT_ROOT"
    git checkout -q -b my-feature
    _make_upr_change "$folder_name" "$title" "$issue_url"
}

# Helper: assert outcome from the "No PR for current branch" scenario is followed.
_assert_no_pr_base_outcome() {
    [ "$status" -eq 0 ]
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"## upr_success"* ]]
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr create --web"* ]]
}

# --- PR already exists ---

@test "action upr: PR exists for current branch, OPEN" {
    _setup_upr_branch
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'

    uspecs action upr
    [ "$status" -eq 0 ]
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"## upr_already_exists"* ]]
    [[ "$output" == *"https://github.com/org/repo/pull/42"* ]]

    # gh pr view --web was called to open browser
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr view --web"* ]]
}

@test "action upr: PR exists for current branch, CLOSED" {
    _setup_upr_branch
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"CLOSED","url":"https://github.com/org/repo/pull/42"}'

    uspecs action upr
    [ "$status" -eq 0 ]

    # Should proceed with PR creation, not show already_exists or already_merged
    [[ "$output" == *"## upr_success"* ]]
    [[ "$output" != *"## upr_already_exists"* ]]
    [[ "$output" != *"## upr_already_merged"* ]]

    # gh pr create --web was called
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr create --web"* ]]
}

@test "action upr: PR exists for current branch, MERGED" {
    _setup_upr_branch
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"MERGED","url":"https://github.com/org/repo/pull/42"}'

    uspecs action upr
    [ "$status" -eq 0 ]

    # Should show already_merged notification and proceed with PR creation
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"PR #42 for this branch was already merged"* ]]
    [[ "$output" == *"## upr_success"* ]]
    [[ "$output" != *"## upr_already_exists"* ]]

    # gh pr create --web was called
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr create --web"* ]]
}

# --- Successful creation flow ---

# Verifies: single commit skips squash, open browser, output next steps (no restore instructions)
@test "action upr: No PR for current branch: single commit, squash skipped" {
    _setup_upr_branch

    uspecs action upr
    [ "$status" -eq 0 ]

    # Output contains no-squash success prompt (no restore instructions)
    [[ "$output" == *"## upr_success_no_squash"* ]]
    [[ "$output" != *"git reset --hard"* ]]

    # gh pr create --web was called
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr create --web"* ]]

    # Still one commit beyond merge-base
    cd "$PROJECT_ROOT"
    local count
    count=$(git rev-list --count origin/main..HEAD)
    [ "$count" -eq 1 ]
}

# Verifies: multiple commits are squashed, force-pushed, restore instructions shown
@test "action upr: No PR for current branch: multiple commits squashed" {
    cd "$PROJECT_ROOT"
    git checkout -q -b multi-commit-branch
    _make_upr_change "2601010000-multi-commit" "Multi commit change"

    # Add a second commit
    echo "extra" >> "$PROJECT_ROOT/uspecs/changes/2601010000-multi-commit/change.md"
    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "second commit"

    # Record pre-squash HEAD to verify it appears in the output
    local pre_head
    pre_head=$(git -C "$PROJECT_ROOT" rev-parse --short HEAD)

    uspecs action upr
    [ "$status" -eq 0 ]

    # Output contains success prompt with restore instructions
    [[ "$output" == *"## upr_success"* ]]
    [[ "$output" != *"## upr_success_no_squash"* ]]
    [[ "$output" == *"$pre_head"* ]]

    # Branch was squashed: only one commit beyond merge-base
    local count
    count=$(git -C "$PROJECT_ROOT" rev-list --count origin/main..HEAD)
    [ "$count" -eq 1 ]
}

# Verifies WCF remains active (not archived) when engineer creates a PR
@test "action upr: No PR for current branch: WCF is active" {
    cd "$PROJECT_ROOT"
    git checkout -q -b active-wcf-branch
    local folder_name="2601010000-active-wcf"
    _make_upr_change "$folder_name" "Active WCF"

    uspecs action upr
    [ "$status" -eq 0 ]

    # WCF remains active (not archived)
    [ -d "$PROJECT_ROOT/uspecs/changes/$folder_name" ]
    [ ! -d "$PROJECT_ROOT/uspecs/changes/archive" ] || \
        [ "$(find "$PROJECT_ROOT/uspecs/changes/archive" -type d -name "*active-wcf" | wc -l)" -eq 0 ]

    _assert_no_pr_base_outcome
}

# Verifies tracking is set before squash/force-push
@test "action upr: No PR for current branch: branch has no upstream" {
    cd "$PROJECT_ROOT"
    git checkout -q -b no-upstream-upr-branch
    _make_upr_change "2601010000-no-upstream-upr" "No upstream"
    # Do NOT push or set upstream -- branch has no tracking remote

    uspecs action upr
    [ "$status" -eq 0 ]

    # Upstream was set (branch now tracks origin/no-upstream-upr-branch)
    local tracking
    tracking=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null || true)
    [[ "$tracking" == "origin/no-upstream-upr-branch" ]]

    _assert_no_pr_base_outcome
}

@test "action upr: No PR for current branch: WCF already archived" {
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

    uspecs action upr
    [ "$status" -eq 0 ]
    [[ "$output" == *"## upr_success"* ]]
}

# --- PR title and commit message ---

@test "action upr: No PR for current branch: PR title and commit message, change has issue_url" {
    _setup_upr_branch "2601010000-issue-change" "Fix the bug" "https://github.com/org/repo/issues/42"

    uspecs action upr
    _assert_no_pr_base_outcome

    # gh pr create was called with title containing issue id
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"[42] Fix the bug"* ]]

    # gh pr create body contains change.md content with frontmatter delimiters stripped
    local gh_body
    gh_body=$(cat "$BATS_TEST_TMPDIR/gh.body")
    [[ "$gh_body" == *"Change request: Fix the bug"* ]]
    # Frontmatter fields appear as plain text (no fenced code block, no --- delimiters)
    [[ "$gh_body" == *"change_id:"* ]]
    [[ "$gh_body" != *'```'* ]]
    [[ "$gh_body" != *"---"* ]]
    # Note: commit message is only rewritten when squashing (multiple commits)
}

@test "action upr: No PR for current branch: PR title and commit message, change does not have issue_url" {
    _setup_upr_branch "2601010000-no-issue" "Add feature"

    uspecs action upr
    _assert_no_pr_base_outcome

    # gh pr create was called with title = change_title only
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"--title Add feature"* ]]

    # gh pr create body contains change.md content with frontmatter delimiters stripped
    local gh_body
    gh_body=$(cat "$BATS_TEST_TMPDIR/gh.body")
    [[ "$gh_body" == *"Change request: Add feature"* ]]
    # Frontmatter fields appear as plain text (no fenced code block, no --- delimiters)
    [[ "$gh_body" == *"change_id:"* ]]
    [[ "$gh_body" != *'```'* ]]
    [[ "$gh_body" != *"---"* ]]
    # Note: commit message is only rewritten when squashing (multiple commits)
}

@test "action upr: No PR for current branch: PR body is truncated when change.md is large" {
    cd "$PROJECT_ROOT"
    git checkout -q -b large-body-branch
    local folder_name="2601010000-large-change"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    {
        echo '---'
        echo "registered_at: 2026-01-01T00:00:00Z"
        echo "change_id: $folder_name"
        echo '---'
        echo ''
        echo '# Change request: Large change'
        echo ''
        # Generate content well over 4000 chars
        for i in $(seq 1 200); do
            echo "Line $i: This is filler text to make the change.md body exceed the 4000 character limit for PR body truncation."
        done
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"
    git add .
    git commit -q -m "add large change"

    uspecs action upr
    _assert_no_pr_base_outcome

    local gh_body
    gh_body=$(cat "$BATS_TEST_TMPDIR/gh.body")
    # Body must contain the truncation notice
    [[ "$gh_body" == *"(truncated -- see change.md for full details)"* ]]
    # Body size should be reasonable (truncated content + notice, under ~4200)
    local body_size
    body_size=${#gh_body}
    (( body_size < 4200 ))
}

# --- Edge cases ---

@test "action upr: Validation rejects, no changes since branching from default branch" {
    cd "$PROJECT_ROOT"
    git checkout -q -b empty-feature

    uspecs action upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No changes detected"* ]]
}

# Git validations#Project inside Git working tree
@test "action upr: Validation rejects, no git repository" {
    rm -rf "$PROJECT_ROOT/.git"
    cd "$PROJECT_ROOT"

    uspecs action upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No git repository"* ]]
}

# Git validations#Git working tree is clean
@test "action upr: Validation rejects, working tree has uncommitted changes" {
    _setup_upr_branch
    echo "dirty" > "$PROJECT_ROOT/dirty-file.txt"

    uspecs action upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"uncommitted changes"* ]]
}

# Git validations#Git working tree is clean
@test "action upr: Validation rejects, current branch is the default branch" {
    cd "$PROJECT_ROOT"

    uspecs action upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"default branch"* ]]
}

# Change Folder validations#Exactly one Working Change Folder
@test "action upr: Validation rejects, No Working Change Folder exists" {
    cd "$PROJECT_ROOT"
    git checkout -q -b no-wcf-branch
    # Make a change outside changes_folder so diff is non-empty
    echo "content" > "$PROJECT_ROOT/some-file.txt"
    git add .
    git commit -q -m "non-change-folder commit"

    uspecs action upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No Working Change Folder"* ]]
}

# Change Folder validations#Exactly one Working Change Folder
@test "action upr: Validation rejects, Multiple Working Change Folder exists" {
    cd "$PROJECT_ROOT"
    git checkout -q -b multi-wcf-branch

    # Create two change folders
    _make_upr_change "2601010000-first-change" "First change"
    _make_upr_change "2601010000-second-change" "Second change"

    uspecs action upr
    [ "$status" -ne 0 ]

    # Verify error lists both folders
    [[ "${stderr:-}" == *"Multiple Working Change Folders"* ]]
    [[ "${stderr:-}" == *"2601010000-first-change"* ]]
    [[ "${stderr:-}" == *"2601010000-second-change"* ]]
}

# Change Folder validations#All todo items are completed
@test "action upr: Validation rejects, change folder has uncompleted todo items" {
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

    uspecs action upr
    [ "$status" -ne 0 ]

    # Verify detailed error message with file names
    [[ "${stderr:-}" == *"uncompleted todo item"* ]]
    [[ "${stderr:-}" == *"change.md"* ]]
    [[ "${stderr:-}" == *"impl.md"* ]]
    [[ "${stderr:-}" == *"Complete"* ]]
}
