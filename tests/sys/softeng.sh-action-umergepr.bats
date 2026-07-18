#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# Feature: Merge pull request
# Engineer asks AI Agent to merge a PR associated with the current branch

# Helper: create a change folder with a proper heading for md_read_title.
# Usage: _make_umergepr_change <folder_name> <title>
# shellcheck disable=SC2120  # Second argument is optional with default
_make_umergepr_change() {
    local folder_name="$1"
    local title="${2:-Test change title}"

    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    {
        echo '---'
        echo "change_id: $folder_name"
        echo '---'
        echo ''
        echo "# Change request: $title"
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"

    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "add $folder_name"
}

# Helper: set up a git repo with an `origin` remote and a feature branch with
# a WCF and upstream ready for action umergepr. Returns with CWD in
# $PROJECT_ROOT on the feature branch. Tests that need git+origin but don't
# go through this helper must call _setup_git_origin themselves (the default
# setup() no longer inits git).
# shellcheck disable=SC2120  # Arguments are optional with defaults
_setup_umergepr_branch() {
    local folder_name="${1:-2601010000-test-change}"
    local title="${2:-Test change title}"

    _setup_git_origin
    git checkout -q -b my-feature
    _make_umergepr_change "$folder_name" "$title"

    # Push to origin and set upstream
    git push -q origin my-feature
    git branch --set-upstream-to=origin/my-feature
}

# Delete the configured upstream branch remotely while retaining its local
# tracking ref, reproducing the state left by a remote-side branch deletion.
_delete_umergepr_upstream_branch() {
    local upstream_head
    upstream_head=$(git rev-parse '@{upstream}')
    git push -q origin --delete my-feature
    git update-ref refs/remotes/origin/my-feature "$upstream_head"
}

# ---------------------------------------------------------------------------
# Scenarios without a Rule
# ---------------------------------------------------------------------------

@test "umergepr: scn: PR not found" {
    # Given no open PR exists for the current branch
    # When Engineer invokes umergepr action
    # Then message "No open PR found for the current branch" is displayed

    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch

    # PR-not-found handling does not validate local commits or the remote ref.
    echo "local-only" > no-pr-local.txt
    git add no-pr-local.txt
    git commit -q -m "local commit without PR"
    _delete_umergepr_upstream_branch

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
    [[ "${stderr:-}" != *"Push them manually"* ]]
    [ -z "$(git ls-remote --heads origin my-feature)" ]

    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" != *"pr update-branch"* ]]
    [[ "$gh_calls" != *"pr merge"* ]]
}

# ---------------------------------------------------------------------------
# Rule: Handling PR in OPEN state
# Background: PR associated with the current branch is in OPEN state
# ---------------------------------------------------------------------------

@test "umergepr: scn: PR in OPEN state" {
    # Given PR associated with the current branch is in OPEN state
    # Given local HEAD is fully present in the configured upstream
    # When Engineer invokes umergepr action
    # Then PR branch is updated with latest base via gh pr update-branch
    # And Attempt to merge PR is made with -s -d options
    # And pr_url is displayed in the success message
    # And Engineer is provided with restore instructions to recover the local branch

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

@test "umergepr: scn: PR in OPEN state with pre-existing unpushed commits" {
    # Given PR associated with the current branch is in OPEN state
    # Given current branch has commits absent from its configured upstream
    # When Engineer invokes umergepr action
    # Then Engineer is instructed to push the commits manually
    # And Working Change Folder is not archived
    # And PR branch is not updated or merged

    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch

    echo "local-only" > local-only.txt
    git add local-only.txt
    git commit -q -m "unpushed local commit"

    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"commits that are not present in configured upstream 'origin/my-feature'"* ]]
    [[ "${stderr:-}" == *"Push them manually with 'git push'"* ]]

    [ -d "$PROJECT_ROOT/uspecs/changes/2601010000-test-change" ]
    [ ! -e "$PROJECT_ROOT/uspecs/changes/archive" ]

    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" != *"pr update-branch"* ]]
    [[ "$gh_calls" != *"pr merge"* ]]
}

@test "umergepr: scn: PR in OPEN state without upstream branch" {
    # Given PR associated with the current branch is in OPEN state
    # Given configured upstream branch "origin/my-feature" does not exist remotely
    # When Engineer invokes umergepr action
    # Then Engineer is instructed how to recreate upstream branch "origin/my-feature"
    # And Working Change Folder is not archived
    # And PR branch is not updated or merged

    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch
    _delete_umergepr_upstream_branch

    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Configured upstream branch 'origin/my-feature' does not exist"* ]]
    [[ "${stderr:-}" == *"git push origin HEAD:my-feature"* ]]

    [ "$(git symbolic-ref --short HEAD)" = "my-feature" ]
    [ -d "$PROJECT_ROOT/uspecs/changes/2601010000-test-change" ]
    [ ! -e "$PROJECT_ROOT/uspecs/changes/archive" ]
    [ "$(git rev-parse refs/remotes/origin/my-feature)" = "$(git rev-parse HEAD)" ]
    [ -z "$(git ls-remote --heads origin my-feature)" ]

    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" != *"pr update-branch"* ]]
    [[ "$gh_calls" != *"pr merge"* ]]
}

@test "umergepr: scn: PR in OPEN state: Configured upstream tracking information is stale" {
    # Given PR associated with the current branch is in OPEN state
    # Given latest configured upstream contains local HEAD
    # And local upstream tracking information is stale
    # When Engineer invokes umergepr action
    # Then latest configured upstream is used to determine that local HEAD is fully pushed
    # And outcome from the base scenario is followed

    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch

    local pushed_head stale_head
    pushed_head=$(git rev-parse HEAD)
    stale_head=$(git rev-parse HEAD^)
    [ "$(git ls-remote --heads origin my-feature | awk '{print $1}')" = "$pushed_head" ]
    git update-ref refs/remotes/origin/my-feature "$stale_head"
    [ -n "$(git rev-list '@{upstream}..HEAD')" ]

    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'

    uspecs action umergepr
    [ "$status" -eq 0 ]
    [[ "$output" == *"umergepr_success"* ]]
    [[ "$output" == *"Fetching configured upstream origin/my-feature"* ]]
    [[ "${stderr:-}" != *"Push them manually"* ]]

    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr update-branch"* ]]
    [[ "$gh_calls" == *"pr merge --squash --delete-branch"* ]]
}

@test "umergepr: scn: PR in OPEN state: Attempt to merge PR fails" {
    # Given PR associated with the current branch is in OPEN state
    # When Attempt to merge PR fails
    # Then PR is opened in the browser
    # And Engineer is prompted to handle PR manually and run umergepr again

    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_MERGE_FAIL=1

    local pre_archive_head
    pre_archive_head=$(git rev-parse HEAD)

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

    # The generated archive commit was pushed before the merge attempt.
    local remote_head
    remote_head=$(git ls-remote --heads origin my-feature | awk '{print $1}')
    [ -n "$remote_head" ]
    [ "$remote_head" != "$pre_archive_head" ]
    [ "$remote_head" = "$(git rev-parse HEAD)" ]
    [ "$(git log -1 --format=%s "$remote_head")" = "Archive 2601010000-test-change" ]
}

@test "umergepr: scn: PR in OPEN state: WCF is active" {
    # Given PR associated with the current branch is in OPEN state
    # Given Working Change Folder is active
    # When Engineer invokes umergepr action
    # Then Working Change Folder is archived
    # And commit is made with message "Archive {wrk_change_folder}"
    # And archive commit is pushed automatically to the configured upstream
    # And outcome from the base scenario is followed

    _setup_git_origin
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

@test "umergepr: scn: PR in OPEN state: Archive commit cannot be confirmed upstream: automatic push fails" {
    # Given PR associated with the current branch is in OPEN state
    # Given Working Change Folder is active
    # When automatic push of the archive commit fails
    # Then umergepr action stops with an error
    # And PR branch is not updated or merged
    # Examples:
    #   | condition                                  |
    #   | automatic push of the archive commit fails |

    _setup_umergepr_branch "2601010000-push-failure" "Push failure"

    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'echo "simulated archive push failure" >&2' \
        'exit 1' \
        > "$PROJECT_ROOT/.git/hooks/pre-push"
    chmod +x "$PROJECT_ROOT/.git/hooks/pre-push"

    local pre_archive_head
    pre_archive_head=$(git rev-parse HEAD)

    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "$output" == *"Pushing archive commit"* ]]
    [[ "${stderr:-}" == *"simulated archive push failure"* ]]
    [[ "${stderr:-}" == *"Failed to push archive commit"* ]]

    local remote_head
    remote_head=$(git ls-remote --heads origin my-feature | awk '{print $1}')
    [ "$remote_head" = "$pre_archive_head" ]

    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" != *"pr update-branch"* ]]
    [[ "$gh_calls" != *"pr merge"* ]]
}

@test "umergepr: scn: PR in OPEN state: Archive commit cannot be confirmed upstream: configured upstream still lacks the archive commit" {
    # Given PR associated with the current branch is in OPEN state
    # Given Working Change Folder is active
    # When configured upstream still lacks the archive commit
    # Then umergepr action stops with an error
    # And PR branch is not updated or merged
    # Examples:
    #   | condition                                          |
    #   | configured upstream still lacks the archive commit |

    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch

    local origin_repo pre_archive_head
    origin_repo=$(git remote get-url origin)
    pre_archive_head=$(git rev-parse HEAD)
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'while read -r old new ref; do' \
        "    if [[ \"\$ref\" == \"refs/heads/my-feature\" ]]; then" \
        "        git --git-dir=. update-ref \"\$ref\" \"\$old\" \"\$new\"" \
        '    fi' \
        'done' \
        > "$origin_repo/hooks/post-receive"
    chmod +x "$origin_repo/hooks/post-receive"

    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"OPEN","url":"https://github.com/org/repo/pull/42"}'

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "$output" == *"Pushing archive commit"* ]]
    [[ "${stderr:-}" == *"commits that are not present in configured upstream 'origin/my-feature'"* ]]
    [[ "${stderr:-}" == *"Push them manually with 'git push'"* ]]

    local remote_head
    remote_head=$(git ls-remote --heads origin my-feature | awk '{print $1}')
    [ "$remote_head" = "$pre_archive_head" ]
    [ "$(git log -1 --format=%s HEAD)" = "Archive 2601010000-test-change" ]

    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" != *"pr update-branch"* ]]
    [[ "$gh_calls" != *"pr merge"* ]]
}

@test "umergepr: scn: PR in OPEN state: upstream remote exists" {
    # Given PR associated with the current branch is in OPEN state
    # Given upstream remote exists
    # When Attempt to merge PR succeeds
    # Then branch is deleted from origin (fork) if it exists, via git push origin --delete
    # And local default branch is checked out
    # And pr_remote/default_branch is fetched
    # And if local default branch has diverged from pr_remote/default_branch, divergence details are logged and sync is skipped
    # And if fast-forward is possible, fetch+ff is retried for up to 5 seconds until WCF in the default branch is detected
    # And default_branch is pushed to origin after fast-forward
    # And errors are logged but do not block completion

    _setup_git_origin

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


# ---------------------------------------------------------------------------
# Rule: Handling PR in MERGED state
# Background: PR associated with the current branch is in MERGED state
# ---------------------------------------------------------------------------


@test "umergepr: scn: PR in MERGED state" {
    # Given PR associated with the current branch is in MERGED state
    # Given local HEAD is fully present in the configured upstream
    # When Engineer invokes umergepr action
    # Then PR is opened in the browser
    # And local branch, upstream tracking ref and origin branch are deleted, errors are ignored
    # And Engineer is informed about state and how to restore local branch if needed

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
    [[ "$output" == *"umergepr_merged"* ]]
    [[ "$output" == *"PR #42 is in MERGED state"* ]]
    [[ "$output" == *"git branch my-feature"* ]]

    # Verify gh pr view --web was called
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr view --web"* ]]

    # Verify origin branch was deleted
    run git -C "$PROJECT_ROOT" ls-remote --heads origin my-feature
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "umergepr: scn: PR in MERGED state without upstream branch" {
    # Given PR associated with the current branch is in MERGED state
    # Given configured upstream branch "origin/my-feature" does not exist remotely
    # And current branch "my-feature" contains a local-only commit
    # When Engineer invokes umergepr action
    # Then local default branch is checked out
    # And local branch "my-feature" and upstream tracking ref "origin/my-feature" are deleted
    # And no remote branch deletion is attempted
    # And Engineer is informed about state and how to restore local branch if needed

    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch
    _delete_umergepr_upstream_branch

    echo "local-only" > merged-missing-upstream.txt
    git add merged-missing-upstream.txt
    git commit -q -m "local commit after remote branch deletion"
    local local_head
    local_head=$(git rev-parse HEAD)

    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"MERGED","url":"https://github.com/org/repo/pull/42"}'

    uspecs action umergepr
    [ "$status" -eq 0 ]
    [[ "$output" == *"Configured upstream origin/my-feature no longer exists"* ]]
    [[ "$output" == *"cleaning up local branch state only"* ]]
    [[ "$output" == *"umergepr_merged"* ]]
    [[ "$output" == *"git branch my-feature $local_head"* ]]
    [[ "$output" != *"Deleting branch my-feature from origin"* ]]

    [ "$(git symbolic-ref --short HEAD)" = "main" ]
    ! git show-ref --verify --quiet refs/heads/my-feature
    ! git show-ref --verify --quiet refs/remotes/origin/my-feature
    [ -z "$(git ls-remote --heads origin my-feature)" ]
}

@test "umergepr: scn: PR in MERGED state with unpushed commits" {
    # Given PR associated with the current branch is in MERGED state
    # Given current branch has commits absent from its configured upstream
    # When Engineer invokes umergepr action
    # Then Engineer is instructed to push the commits manually
    # And local branch, upstream tracking ref and origin branch are retained

    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch

    local remote_head
    remote_head=$(git ls-remote --heads origin my-feature | awk '{print $1}')
    echo "local-only" > merged-local-only.txt
    git add merged-local-only.txt
    git commit -q -m "unpushed commit after merge"
    local local_head
    local_head=$(git rev-parse HEAD)

    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"MERGED","url":"https://github.com/org/repo/pull/42"}'

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Push them manually with 'git push'"* ]]

    [ "$(git symbolic-ref --short HEAD)" = "my-feature" ]
    [ "$(git rev-parse refs/heads/my-feature)" = "$local_head" ]
    [ "$(git rev-parse refs/remotes/origin/my-feature)" = "$remote_head" ]
    [ "$(git ls-remote --heads origin my-feature | awk '{print $1}')" = "$remote_head" ]

    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr view --web"* ]]
}

# ---------------------------------------------------------------------------
# Scenarios without a Rule
# ---------------------------------------------------------------------------

@test "umergepr: scn: PR in non-MERGED, non-OPEN state" {
    # Given PR associated with the current branch is in a non-OPEN, non-MERGED state
    # When Engineer invokes umergepr action
    # Then PR is opened in the browser
    # And no local or remote branches are deleted
    # And Engineer is informed about state

    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch

    # Non-OPEN, non-MERGED handling does not validate unpushed commits.
    echo "local-only" > closed-local-only.txt
    git add closed-local-only.txt
    git commit -q -m "local commit on closed PR"

    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_EXISTS=1
    # shellcheck disable=SC2030,SC2031
    export GH_STUB_PR_JSON='{"number":42,"state":"CLOSED","url":"https://github.com/org/repo/pull/42"}'

    uspecs action umergepr
    [ "$status" -eq 0 ]

    # Verify structured output tags and informational message
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"PR #42 is in CLOSED state"* ]]
    # No restore instructions because nothing was deleted
    [[ "$output" != *"git branch my-feature"* ]]
    [[ "${stderr:-}" != *"Push them manually"* ]]

    # Verify gh pr view --web was called
    local gh_calls
    gh_calls=$(cat "$BATS_TEST_TMPDIR/gh.calls")
    [[ "$gh_calls" == *"pr view --web"* ]]

    # Verify local branch is preserved
    run git -C "$PROJECT_ROOT" rev-parse --verify --quiet refs/heads/my-feature
    [ "$status" -eq 0 ]

    # Verify upstream tracking ref is preserved
    run git -C "$PROJECT_ROOT" rev-parse --verify --quiet refs/remotes/origin/my-feature
    [ "$status" -eq 0 ]

    # Verify origin branch is preserved
    run git -C "$PROJECT_ROOT" ls-remote --heads origin my-feature
    [ "$status" -eq 0 ]
    [[ "$output" == *"refs/heads/my-feature"* ]]
}

# ---------------------------------------------------------------------------
# Rule: Working with edge cases
# Scenario Outline: Validation
# Given <condition>
# When Engineer invokes umergepr action
# Then AI Agent displays error and stops
# Examples:
#   | condition                      | message           |
#   | current branch has no upstream | same as condition |
# And Examples includes examples from the "Git validations#Git working tree is clean" scenario
# And Examples includes examples from the "Change Folder validations#Exactly one Working Change Folder" scenario
# ---------------------------------------------------------------------------

# Git validations#Project inside Git working tree
@test "umergepr: scn: Project inside Git working tree: no git repo" {
    # Given path "$PROJECT_ROOT" is not inside git working tree
    # When git-dependent action is invoked
    # Then AI Agent displays error message and stops

    # Uses the cheap default setup() -- no git repo initialised.

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No git repository"* ]]
}

# Git validations#Git working tree is clean
@test "umergepr: scn: Git working tree is clean: uncommitted changes" {
    # Given working tree has uncommitted changes
    # When action that requires clean git repository is invoked
    # Then AI Agent displays error message and stops

    # shellcheck disable=SC2119  # No arguments needed, uses defaults
    _setup_umergepr_branch
    echo "uncommitted" > "$PROJECT_ROOT/dirty.txt"

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"uncommitted changes"* ]]
}

# Git validations#Git working tree is clean
@test "umergepr: scn: Git working tree is clean: current branch is default branch" {
    # Given current branch is the default branch
    # When action that requires clean git repository is invoked
    # Then AI Agent displays error message and stops

    _setup_git_origin
    git checkout -q main

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Current branch is the default branch"* ]]
}

@test "umergepr: scn: Validation: current branch has no upstream" {
    # Given current branch has no upstream
    # When Engineer invokes umergepr action
    # Then AI Agent displays error and stops

    _setup_git_origin
    git checkout -q -b no-upstream-branch
    _make_umergepr_change "2601010000-no-upstream" "No upstream"
    # Do NOT set upstream

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"has no upstream"* ]]
}

# Change Folder validations#Exactly one Working Change Folder
@test "umergepr: scn: Exactly one Working Change Folder: no WCF" {
    # Given No Working Change Folder exists
    # When action that requires a single Working Change Folder is invoked
    # Then AI Agent displays error message and stops

    _setup_git_origin
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

@test "umergepr: scn: Exactly one Working Change Folder: multiple WCFs" {
    # Given Multiple Working Change Folders exist
    # When action that requires a single Working Change Folder is invoked
    # Then AI Agent displays error message and stops

    _setup_git_origin
    git checkout -q -b multi-wcf-branch
    _make_umergepr_change "2601010000-first-change" "First change"
    _make_umergepr_change "2601010000-second-change" "Second change"
    git push -q origin multi-wcf-branch
    git branch --set-upstream-to=origin/multi-wcf-branch

    uspecs action umergepr
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Multiple Working Change Folders"* ]]
}
