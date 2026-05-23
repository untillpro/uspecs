#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# Helper: create a change folder with a proper heading for md_read_title.
# Usage: _make_upr_change <folder_name> <title> [issue_url] [type] [scope] [breaking] [body_shape]
# type defaults to "feat"; scope and breaking are omitted when empty.
# body_shape controls which initial body section(s) are written:
#   "why_what" (default) -- ## Why + ## What sections
#   "why_how"            -- ## Why + ## How sections
#   "context"            -- ## Context section (issue-case shape, --fetchable)
#   "none"               -- no body sections (frontmatter-only body)
# ## How and ## Functional design are appended unless body_shape is "why_how" or "none".
# upr emits all body sections that fit within the PR body size limits.
_make_upr_change() {
    local folder_name="$1"
    local title="${2:-Test change title}"
    local issue_url="${3:-}"
    local type="${4:-feat}"
    local scope="${5:-}"
    local breaking="${6:-}"
    local body_shape="${7:-why_what}"

    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    {
        echo '---'
        echo "change_id: $folder_name"
        if [[ -n "$issue_url" ]]; then
            echo "issue_url: $issue_url"
        fi
        echo "type: $type"
        if [[ -n "$scope" ]]; then
            echo "scope: $scope"
        fi
        if [[ -n "$breaking" ]]; then
            echo "breaking: $breaking"
        fi
        echo '---'
        echo ''
        echo "# Change request: $title"
        echo ''
        case "$body_shape" in
            why_what)
                echo '## Why'
                echo ''
                echo 'Why narrative.'
                echo ''
                echo '## What'
                echo ''
                echo 'What narrative.'
                echo ''
                ;;
            why_how)
                echo '## Why'
                echo ''
                echo 'Why narrative.'
                echo ''
                echo '## How'
                echo ''
                echo 'How narrative.'
                echo ''
                ;;
            context)
                echo '## Context'
                echo ''
                echo 'Context narrative.'
                echo ''
                echo 'See [issue.md](issue.md) for the details.'
                echo ''
                ;;
            none)
                ;;
            *)
                echo "_make_upr_change: unknown body_shape: $body_shape" >&2
                return 1
                ;;
        esac
        if [[ "$body_shape" != "why_how" && "$body_shape" != "none" ]]; then
            echo '## How'
            echo ''
            echo 'How narrative.'
            echo ''
        fi
        if [[ "$body_shape" != "why_how" && "$body_shape" != "none" ]]; then
            echo '## Functional design'
            echo ''
            echo 'SENTINEL_FILTERED_OUT'
        fi
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"

    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "add $folder_name"
}

# Helper: set up a git repo with an `origin` remote and a feature branch with
# a WCF ready for action upr. Returns with CWD in $PROJECT_ROOT on the feature
# branch. Tests that need git+origin but don't go through this helper must
# call _setup_git_origin themselves (the default setup() no longer inits git).
_setup_upr_branch() {
    local folder_name="${1:-2601010000-test-change}"
    local title="${2:-Test change title}"
    local issue_url="${3:-}"
    local type="${4:-feat}"
    local scope="${5:-}"
    local breaking="${6:-}"
    local body_shape="${7:-why_what}"

    _setup_git_origin
    git checkout -q -b my-feature
    _make_upr_change "$folder_name" "$title" "$issue_url" "$type" "$scope" "$breaking" "$body_shape"
}

# Helper: assert outcome from the "No PR for current branch" scenario.
# Branch is always squashed into a single commit and force-pushed.
_assert_no_pr_base_outcome() {
    [ "$status" -eq 0 ]
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"upr_success"* ]]
    [[ "$output" != *"upr_success_no_squash"* ]]
    [[ "$output" == *"git reset --keep"* ]]
    # PR was created programmatically (not --web) and then opened in browser
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr create"* ]]
    [[ "$gh_calls" != *"pr create --web"* ]]
    [[ "$gh_calls" == *"pr view --web"* ]]
    # pr_url appears in output
    [[ "$output" == *"https://github.com/org/repo/pull/42"* ]]
    # Always squashed to one commit beyond merge-base
    local count
    count=$(git -C "$PROJECT_ROOT" rev-list --count origin/main..HEAD)
    [ "$count" -eq 1 ]
}

# Helper: assert gh pr create --title argument and the squashed HEAD commit
# subject match <expected_subject>; assert the squash commit body carries
# the "See change.md for details" trailer; if <issue_id> is given assert
# a "Closes #<issue_id>" trailer also appears and follows the see-details
# trailer.
# Usage: _assert_subject_and_trailers <expected_subject> [<issue_id>]
_assert_subject_and_trailers() {
    local expected_subject="$1"
    local issue_id="${2:-}"

    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"--title $expected_subject"* ]]

    local subject body
    subject=$(git -C "$PROJECT_ROOT" log -1 --format=%s HEAD)
    [ "$subject" = "$expected_subject" ]

    body=$(git -C "$PROJECT_ROOT" log -1 --format=%B HEAD)
    [[ "$body" == *"See change.md for details"* ]]
    if [[ -n "$issue_id" ]]; then
        [[ "$body" == *"Closes #$issue_id"* ]]
        # see-details trailer appears before Closes trailer
        local before_see before_closes
        before_see="${body%%See change.md for details*}"
        before_closes="${body%%Closes #*}"
        [ "${#before_see}" -lt "${#before_closes}" ]
    else
        [[ "$body" != *"Closes #"* ]]
    fi
}

# Helper: assert PR body format invariants.
# Usage: _assert_pr_body_format [body_shape]
# Invariants always asserted:
#   - frontmatter wrapped in a ```yaml fenced code block
#   - no bare "---" delimiters outside the fence
#   - no omission note when the PR body fits within the size limits
# body_shape selects which body sections must be present:
#   "why_what" (default) -- ## Why, ## What, ## How, and ## Functional design present
#   "why_how"            -- ## Why and ## How present, ## What absent
#   "context"            -- ## Context, ## How, and ## Functional design present, ## Why and ## What absent
#   "none"               -- no body sections (frontmatter-only body)
_assert_pr_body_format() {
    local body_shape="${1:-why_what}"
    local gh_body
    gh_body=$(cat "$BATS_TEST_TMPDIR/gh.body")
    [[ "$gh_body" == *'```yaml'*'change_id:'*'```'* ]]
    [[ "$gh_body" != *"---"* ]]
    [[ "$gh_body" != *"Content omitted. See change.md for full details."* ]]

    case "$body_shape" in
        why_what)
            [[ "$gh_body" == *"## Why"* ]]
            [[ "$gh_body" == *"## What"* ]]
            [[ "$gh_body" == *"## How"* ]]
            [[ "$gh_body" == *"## Functional design"*"SENTINEL_FILTERED_OUT"* ]]
            [[ "$gh_body" != *"## Context"* ]]
            ;;
        why_how)
            [[ "$gh_body" == *"## Why"* ]]
            [[ "$gh_body" == *"## How"* ]]
            [[ "$gh_body" != *"## Functional design"* ]]
            [[ "$gh_body" != *"SENTINEL_FILTERED_OUT"* ]]
            [[ "$gh_body" != *"## What"* ]]
            [[ "$gh_body" != *"## Context"* ]]
            ;;
        context)
            [[ "$gh_body" == *"## Context"* ]]
            [[ "$gh_body" == *"## How"* ]]
            [[ "$gh_body" == *"## Functional design"*"SENTINEL_FILTERED_OUT"* ]]
            [[ "$gh_body" != *"## Why"* ]]
            [[ "$gh_body" != *"## What"* ]]
            ;;
        none)
            [[ "$gh_body" != *"## Why"* ]]
            [[ "$gh_body" != *"## What"* ]]
            [[ "$gh_body" != *"## Context"* ]]
            [[ "$gh_body" != *"## How"* ]]
            ;;
        *)
            echo "_assert_pr_body_format: unknown body_shape: $body_shape" >&2
            return 1
            ;;
    esac
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
    [[ "$output" == *"upr_already_exists"* ]]
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
    _assert_no_pr_base_outcome
    [[ "$output" != *"upr_already_exists"* ]]
    [[ "$output" != *"upr_already_merged"* ]]
}

@test "action upr: PR exists for current branch, MERGED" {
    _setup_upr_branch
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"MERGED","url":"https://github.com/org/repo/pull/42"}'

    uspecs action upr
    _assert_no_pr_base_outcome
    [[ "$output" == *"PR #42 for this branch was already merged"* ]]
    [[ "$output" != *"upr_already_exists"* ]]
}

# --- Successful creation flow ---

# Verifies: single user commit + archive commit -> squash, open browser, output next steps
@test "action upr: No PR for current branch: single commit, archive triggers squash" {
    _setup_upr_branch

    uspecs action upr
    _assert_no_pr_base_outcome
}

# Verifies: multiple commits are squashed, force-pushed, restore instructions shown
@test "action upr: No PR for current branch: multiple commits squashed" {
    _setup_git_origin
    git checkout -q -b multi-commit-branch
    _make_upr_change "2601010000-multi-commit" "Multi commit change"

    # Add a second commit
    echo "extra" >> "$PROJECT_ROOT/uspecs/changes/2601010000-multi-commit/change.md"
    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "second commit"

    uspecs action upr
    _assert_no_pr_base_outcome
}

# Verifies WCF is archived by default when engineer creates a PR
@test "action upr: No PR for current branch: WCF is archived by default" {
    _setup_git_origin
    git checkout -q -b active-wcf-branch
    local folder_name="2601010000-active-wcf"
    _make_upr_change "$folder_name" "Active WCF"

    uspecs action upr

    # WCF was archived (no longer in active folder)
    [ ! -d "$PROJECT_ROOT/uspecs/changes/$folder_name" ]
    # Archived folder exists
    [ -d "$PROJECT_ROOT/uspecs/changes/archive" ]
    local archived
    archived=$(find "$PROJECT_ROOT/uspecs/changes/archive" -type d -name "*active-wcf" | wc -l)
    [ "$archived" -ge 1 ]

    _assert_no_pr_base_outcome
}

# Verifies --no-archive keeps WCF active
@test "action upr: No PR for current branch: --no-archive keeps WCF active" {
    _setup_git_origin
    git checkout -q -b no-archive-branch
    local folder_name="2601010000-no-archive-wcf"
    _make_upr_change "$folder_name" "No Archive WCF"

    uspecs action upr --no-archive

    # WCF remains active (not archived)
    [ -d "$PROJECT_ROOT/uspecs/changes/$folder_name" ]
    [ ! -d "$PROJECT_ROOT/uspecs/changes/archive" ] || \
        [ "$(find "$PROJECT_ROOT/uspecs/changes/archive" -type d -name "*no-archive-wcf" | wc -l)" -eq 0 ]

    _assert_no_pr_base_outcome
}

# Verifies tracking is set before squash/force-push
@test "action upr: No PR for current branch: branch has no upstream" {
    _setup_git_origin
    git checkout -q -b no-upstream-upr-branch
    _make_upr_change "2601010000-no-upstream-upr" "No upstream"
    # Do NOT push or set upstream -- branch has no tracking remote

    uspecs action upr

    # Upstream was set (branch now tracks origin/no-upstream-upr-branch)
    local tracking
    tracking=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null || true)
    [[ "$tracking" == "origin/no-upstream-upr-branch" ]]

    _assert_no_pr_base_outcome
}

@test "action upr: No PR for current branch: WCF already archived" {
    _setup_git_origin
    git checkout -q -b archived-wcf-branch

    # Create archived change folder (simulates post-upr state where folder was already archived)
    local archive_path="$PROJECT_ROOT/uspecs/changes/archive/2601/2601010000-archived-change"
    mkdir -p "$archive_path"
    {
        echo '---'
        echo "change_id: 2601010000-archived-change"
        echo "type: feat"
        echo '---'
        echo ''
        echo '# Change request: Archived change'
    } > "$archive_path/change.md"
    git add .
    git commit -q -m "archived WCF"

    uspecs action upr
    _assert_no_pr_base_outcome
}

# --- Construct PR title and commit message ---
#
# Subject template per Conventional Commits v1.0.0:
#   <type>[(<scope>)][!]: <change_title>[ [<issue_id>]]
# Commit body trailer order: "See change.md for details" THEN "Closes #<id>".
# PR title equals the post-squash commit subject.

# type only, no scope, no breaking, no issue
@test "action upr: subject: type only" {
    _setup_upr_branch "2601010000-feat-only" "Add feature" "" "feat" "" ""

    uspecs action upr
    _assert_no_pr_base_outcome

    _assert_subject_and_trailers "feat: Add feature"

    # PR body carries all body sections that fit within the size limits.
    local gh_body
    gh_body=$(cat "$BATS_TEST_TMPDIR/gh.body")
    [[ "$gh_body" == *"## Why"*"Why narrative."* ]]
    [[ "$gh_body" == *"## What"*"What narrative."* ]]
    [[ "$gh_body" == *"## How"*"How narrative."* ]]
    _assert_pr_body_format
}

# type + scope, no breaking, no issue
@test "action upr: subject: type + scope" {
    _setup_upr_branch "2601010000-fix-api" "Fix the bug" "" "fix" "api" ""

    uspecs action upr
    _assert_no_pr_base_outcome

    _assert_subject_and_trailers "fix(api): Fix the bug"
}

# type + multi-scope + issue, no breaking
@test "action upr: subject: type + multi-scope + issue" {
    _setup_upr_branch "2601010000-multi-scope" "Add new flag" \
        "https://github.com/org/repo/issues/42" "feat" "api,cli" ""

    uspecs action upr
    _assert_no_pr_base_outcome

    _assert_subject_and_trailers "feat(api,cli): Add new flag [42]" "42"
}

# type + scope + breaking + issue
@test "action upr: subject: type + scope + breaking + issue" {
    _setup_upr_branch "2601010000-breaking-scope" "Rewrite endpoint" \
        "https://github.com/org/repo/issues/42" "feat" "api" "true"

    uspecs action upr
    _assert_no_pr_base_outcome

    _assert_subject_and_trailers "feat(api)!: Rewrite endpoint [42]" "42"
}

# type + breaking only, no scope, no issue
@test "action upr: subject: type + breaking only" {
    _setup_upr_branch "2601010000-breaking-only" "Drop legacy API" \
        "" "refactor" "" "true"

    uspecs action upr
    _assert_no_pr_base_outcome

    _assert_subject_and_trailers "refactor!: Drop legacy API"
}

# --- Construct PR body ---
#
# pr_body composition includes body content from the first top-level ## section
# after the main heading. It is truncated to 40 lines or 4000 characters
# (whichever hits first), with an omission note appended when truncated.

# 60 short lines inside Why section -> line limit (40) truncates
@test "action upr: No PR for current branch: PR body truncated by line limit" {
    _setup_git_origin
    git checkout -q -b large-body-branch
    local folder_name="2601010000-large-change"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    {
        echo '---'
        echo "change_id: $folder_name"
        echo 'type: feat'
        echo '---'
        echo ''
        echo '# Change request: Large change'
        echo ''
        echo '## Why'
        echo ''
        # 57 filler lines under ## Why -> well past the 40-line cut
        for i in $(seq 1 57); do
            echo "Line $i: short filler"
        done
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"
    git add .
    git commit -q -m "add large change"

    uspecs action upr
    _assert_no_pr_base_outcome

    local gh_body
    gh_body=$(cat "$BATS_TEST_TMPDIR/gh.body")
    [[ "$gh_body" == *"Content omitted. See change.md for full details."* ]]
    # Late lines must be gone (line 57 is well past the 40-line cut)
    [[ "$gh_body" != *"Line 57"* ]]
    # Early lines must be present
    [[ "$gh_body" == *"Line 1: short filler"* ]]
}

# 10 long lines (~500 chars each, ~5000 total) under 40 lines -> char limit truncates
@test "action upr: No PR for current branch: PR body truncated by char limit" {
    _setup_git_origin
    git checkout -q -b large-chars-branch
    local folder_name="2601010000-large-chars"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    {
        echo '---'
        echo "change_id: $folder_name"
        echo 'type: feat'
        echo '---'
        echo ''
        echo '# Change request: Large chars change'
        echo ''
        echo '## Why'
        echo ''
        # 10 long lines under ## Why -> ~5000 chars, over 4000 char limit
        for i in $(seq 1 10); do
            printf 'Line %d: ' "$i"
            printf '%0.s_' $(seq 1 500)
            echo ''
        done
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"
    git add .
    git commit -q -m "add large chars change"

    uspecs action upr
    _assert_no_pr_base_outcome

    local gh_body
    gh_body=$(cat "$BATS_TEST_TMPDIR/gh.body")
    [[ "$gh_body" == *"Content omitted. See change.md for full details."* ]]
    # Body size capped near 4000 (content + notice)
    local body_size
    body_size=${#gh_body}
    (( body_size < 4200 ))
}

# change.md has ## Context (issue-case shape) instead of ## Why + ## What
@test "action upr: Construct PR body: ## Context section" {
    _setup_upr_branch "2601010000-context-shape" "Context shape change" \
        "https://github.com/org/repo/issues/42" "feat" "" "" "context"

    uspecs action upr
    _assert_no_pr_base_outcome

    local gh_body
    gh_body=$(cat "$BATS_TEST_TMPDIR/gh.body")
    # ## Context section is rendered in the PR body
    [[ "$gh_body" == *"## Context"*"Context narrative."* ]]
    [[ "$gh_body" == *"See [issue.md](issue.md)"* ]]
    [[ "$gh_body" == *"## Functional design"*"SENTINEL_FILTERED_OUT"* ]]

    _assert_pr_body_format "context"
}

@test "action upr: Construct PR body: ## Why followed by ## How" {
    _setup_upr_branch "2601010000-why-how" "Why How body change" \
        "" "fix" "" "" "why_how"

    uspecs action upr
    _assert_no_pr_base_outcome

    local gh_body
    gh_body=$(cat "$BATS_TEST_TMPDIR/gh.body")
    [[ "$gh_body" == *"## Why"*"Why narrative."* ]]
    [[ "$gh_body" == *"## How"*"How narrative."* ]]
    [[ "$gh_body" != *"Content omitted. See change.md for full details."* ]]

    _assert_pr_body_format "why_how"
}

@test "action upr: Construct PR body: includes all body sections until size limits" {
    _setup_git_origin
    git checkout -q -b duplicate-what-body-branch
    local folder_name="2601010000-duplicate-what"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    {
        echo '---'
        echo "change_id: $folder_name"
        echo 'type: fix'
        echo '---'
        echo ''
        echo '# Change request: Duplicate What body'
        echo ''
        echo '## Why'
        echo ''
        echo 'Why narrative.'
        echo ''
        echo '## What'
        echo ''
        echo 'What narrative.'
        echo ''
        echo '## Quick start'
        echo ''
        echo '```markdown'
        echo '## What'
        echo ''
        echo 'DUPLICATE_WHAT_FROM_FENCED_EXAMPLE'
        echo '```'
        echo ''
        echo '## Functional design'
        echo ''
        echo 'SENTINEL_FILTERED_OUT'
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"
    git add .
    git commit -q -m "add duplicate what body change"

    uspecs action upr
    _assert_no_pr_base_outcome

    local gh_body
    gh_body=$(cat "$BATS_TEST_TMPDIR/gh.body")
    [[ "$gh_body" == *'```yaml'*"change_id: $folder_name"*'```'* ]]
    [[ "$gh_body" == *"## Why"*"Why narrative."* ]]
    [[ "$gh_body" == *"## What"*"What narrative."* ]]
    [[ "$gh_body" == *"## Quick start"* ]]
    [[ "$gh_body" == *"DUPLICATE_WHAT_FROM_FENCED_EXAMPLE"* ]]
    [[ "$gh_body" == *"## Functional design"*"SENTINEL_FILTERED_OUT"* ]]
    [[ "$gh_body" != *"Content omitted. See change.md for full details."* ]]

    local what_count
    what_count=$(printf '%s\n' "$gh_body" | grep -c '^## What$')
    [ "$what_count" -eq 2 ]
}

# change.md has neither ## Context nor ## Why/## What (frontmatter-only body)
@test "action upr: Construct PR body: no body sections (frontmatter-only)" {
    _setup_upr_branch "2601010000-no-body" "No body sections" \
        "" "feat" "" "" "none"

    uspecs action upr
    _assert_no_pr_base_outcome

    local gh_body
    gh_body=$(cat "$BATS_TEST_TMPDIR/gh.body")
    # Frontmatter is present, wrapped in a yaml code fence
    [[ "$gh_body" == *'```yaml'*"change_id: 2601010000-no-body"*'```'* ]]
    # No body sections appended (Why/What/Context/How/Functional design)
    [[ "$gh_body" != *"## Why"* ]]
    [[ "$gh_body" != *"## What"* ]]
    [[ "$gh_body" != *"## Context"* ]]
    [[ "$gh_body" != *"## How"* ]]
    [[ "$gh_body" != *"SENTINEL_FILTERED_OUT"* ]]

    _assert_pr_body_format "none"
}

# --- Edge cases ---

@test "action upr: Validation rejects, no changes since branching from default branch" {
    _setup_git_origin
    git checkout -q -b empty-feature

    uspecs action upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No changes detected"* ]]
}

# Git validations#Project inside Git working tree
@test "action upr: Validation rejects, no git repository" {
    # Uses the cheap default setup() -- no git repo initialised.

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
    _setup_git_origin

    uspecs action upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"default branch"* ]]
}

# Change Folder validations#Exactly one Working Change Folder
@test "action upr: Validation rejects, No Working Change Folder exists" {
    _setup_git_origin
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
    _setup_git_origin
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
    _setup_git_origin
    git checkout -q -b todo-feature
    local folder_name="2601010000-with-todos"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"

    # Create change.md with uncompleted item
    {
        echo '---'
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

# Change Folder validations#change.md frontmatter has 'type:'
@test "action upr: Validation rejects, change.md frontmatter is missing 'type:' field" {
    # softeng.sh hard-fails when change.md frontmatter does not declare a
    # 'type:' field, and does NOT enumerate the allowed Conventional Commits
    # types inline. The agent is expected to read the list from the uchange
    # dispatch instructions and surface it to the user.
    _setup_git_origin
    git checkout -q -b missing-type-branch
    local folder_name="2601010000-missing-type"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    {
        echo '---'
        echo "change_id: $folder_name"
        echo '---'
        echo ''
        echo '# Change request: Missing type'
        echo ''
        echo '## Why'
        echo ''
        echo 'Why narrative.'
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"
    git add .
    git commit -q -m "add missing-type change"

    uspecs action upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"type"* ]]
    [[ "${stderr:-}" == *"frontmatter"* ]]
    # The error must not enumerate allowed types inline; the canonical
    # list lives in scripts/templates/actions/uchange.yaml only.
    [[ "${stderr:-}" != *"feat"*"fix"* ]]

    # No PR was created in this error case
    if [ -f "$BATS_TEST_TMPDIR/gh.calls" ]; then
        local gh_calls
        gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
        [[ "$gh_calls" != *"pr create"* ]]
    fi
}

# change.md without frontmatter at all -> same hard-fail as missing-type field
@test "action upr: Validation rejects, change.md has no YAML frontmatter" {
    _setup_git_origin
    git checkout -q -b no-frontmatter-branch
    local folder_name="2601010000-no-frontmatter"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    {
        echo '# Change request: No frontmatter change'
        echo ''
        echo '## Why'
        echo ''
        echo 'Why narrative.'
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"
    git add .
    git commit -q -m "add no-frontmatter change"

    uspecs action upr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"type"* ]]
    [[ "${stderr:-}" == *"frontmatter"* ]]
}
