#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

@test "change archive moves change folder to archive/" {
    cd "$PROJECT_ROOT"
    _make_change_folder "2601010000-test-archive"

    uspecs change archive "2601010000-test-archive"
    [ "$status" -eq 0 ]
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2601010000-test-archive" ]
    local archived
    archived=$(find "$PROJECT_ROOT/uspecs/changes/archive" -type d -name "*test-archive" 2>/dev/null | head -1)
    [ -n "$archived" ]
}

@test "change archive with uncompleted items fails" {
    cd "$PROJECT_ROOT"
    local folder_name="2601010000-with-todos"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    printf '%s\n' \
        '---' \
        "registered_at: 2026-01-01T00:00:00Z" \
        "change_id: $folder_name" \
        '---' \
        '' \
        '- [ ] uncompleted task' \
        > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"

    uspecs change archive "$folder_name"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Cannot archive"* ]]
}

@test "change archive when change.md missing fails" {
    cd "$PROJECT_ROOT"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/2601010000-no-change-md"

    uspecs change archive "2601010000-no-change-md"
    [ "$status" -ne 0 ]
    [[ "$output" == *"change.md not found"* ]]
}

_assert_cleanup_complete() {
    local branch_name="${1:-my-feature--pr}"
    # switched to default branch
    [ "$(git -C "$PROJECT_ROOT" branch --show-current)" = "main" ]
    # local PR branch deleted
    if git -C "$PROJECT_ROOT" show-ref --verify --quiet "refs/heads/$branch_name"; then return 1; fi
    # local tracking ref deleted
    if git -C "$PROJECT_ROOT" show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then return 1; fi
    # default branch fast-forwarded to remote tip
    local local_main remote_main
    local_main=$(git -C "$PROJECT_ROOT" rev-parse main)
    remote_main=$(git -C "$PROJECT_ROOT" rev-parse "origin/main")
    [ "$local_main" = "$remote_main" ]
}

@test "change archive -d squashes pushes and deletes branch" {
    cd "$PROJECT_ROOT"

    # Create a PR branch (ends with --pr) and push it to origin.
    git checkout -b my-feature--pr
    git push -q -u origin my-feature--pr

    # Commit a change folder onto the PR branch and push.
    _make_change_folder "2601010000-archive-d-test"
    git push -q origin my-feature--pr

    uspecs change archive "2601010000-archive-d-test" -d
    [ "$status" -eq 0 ]
    # Must have switched back to default branch.
    [ "$(git -C "$PROJECT_ROOT" branch --show-current)" = "main" ]
    # PR branch must be deleted locally.
    if git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/my-feature--pr; then return 1; fi
}

@test "change archive -d when remote branch exists: pushes commit and cleans up" {
    cd "$PROJECT_ROOT"

    git checkout -b my-feature--pr
    git push -q -u origin my-feature--pr
    _make_change_folder "2601010000-archive-remote-exists"

    uspecs change archive "2601010000-archive-remote-exists" -d
    [ "$status" -eq 0 ]

    # push happened: origin still has the PR branch
    local remote_ref
    remote_ref=$(git -C "$PROJECT_ROOT" ls-remote origin "refs/heads/my-feature--pr")
    [ -n "$remote_ref" ]

    _assert_cleanup_complete "my-feature--pr"
}

@test "change archive -d when remote branch gone: skips push and cleans up" {
    cd "$PROJECT_ROOT"

    git checkout -b my-feature--pr
    git push -q -u origin my-feature--pr

    # Simulate remote branch already deleted (e.g. merged on GitHub)
    git push -q origin --delete my-feature--pr

    _make_change_folder "2601010000-archive-remote-gone"

    uspecs change archive "2601010000-archive-remote-gone" -d
    [ "$status" -eq 0 ]

    # push was skipped: origin does not have the PR branch
    local remote_ref
    remote_ref=$(git -C "$PROJECT_ROOT" ls-remote origin "refs/heads/my-feature--pr")
    [ -z "$remote_ref" ]

    _assert_cleanup_complete "my-feature--pr"
}

@test "change archive -d fails when default branch cannot be fast-forwarded" {
    cd "$PROJECT_ROOT"

    git checkout -b my-feature--pr
    git push -q -u origin my-feature--pr
    _make_change_folder "2601010000-archive-ff-fail"

    # Push a commit to origin/main via a temp clone so origin/main advances.
    local origin_path tmp_clone
    origin_path=$(git -C "$PROJECT_ROOT" remote get-url origin)
    tmp_clone="${BATS_TEST_TMPDIR}/tmp-clone"
    git clone -q "$origin_path" "$tmp_clone"
    git -C "$tmp_clone" config user.email "test@test.com"
    git -C "$tmp_clone" config user.name "Test"
    git -C "$tmp_clone" commit --allow-empty -q -m "origin-only commit on main"
    git -C "$tmp_clone" push -q origin main

    # Add a local-only commit on main: now both sides have diverged.
    git checkout -q main
    git commit -q --allow-empty -m "local-only commit on main"
    git checkout -q my-feature--pr

    uspecs change archive "2601010000-archive-ff-fail" -d
    [ "$status" -ne 0 ]
    [[ "$output" == *"Cannot fast-forward"* ]]
}

