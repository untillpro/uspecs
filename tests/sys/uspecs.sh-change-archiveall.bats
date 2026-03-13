#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

@test "change archiveall archives modified change folders and reports counts" {
    cd "$PROJECT_ROOT"

    # Two folders committed locally but not pushed -> both modified vs origin/main
    _make_change_folder "2601010000-all-modified-a"
    _make_change_folder "2601010000-all-modified-b"

    uspecs change archiveall
    [ "$status" -eq 0 ]
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2601010000-all-modified-a" ]
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2601010000-all-modified-b" ]
    local archived_a archived_b
    archived_a=$(find "$PROJECT_ROOT/uspecs/changes/archive" -type d -name "*all-modified-a" 2>/dev/null | head -1)
    archived_b=$(find "$PROJECT_ROOT/uspecs/changes/archive" -type d -name "*all-modified-b" 2>/dev/null | head -1)
    [ -n "$archived_a" ]
    [ -n "$archived_b" ]
    [[ "$output" == *"2 archived"* ]]
}

@test "change archiveall skips folders unchanged vs origin/main" {
    cd "$PROJECT_ROOT"

    # 1. Same as in main: committed and pushed, not modified locally -> unchanged
    _make_change_folder "2601010000-skip-same"
    git push -q origin main

    # 2. Deleted in main: committed and pushed, then removed from origin by another commit
    _make_change_folder "2601010000-skip-del-main"
    git push -q origin main

    # 3. Modified in branch: committed and pushed, then modified locally
    _make_change_folder "2601010000-skip-modified"
    git push -q origin main

    echo "extra" >> "$PROJECT_ROOT/uspecs/changes/2601010000-skip-modified/change.md"
    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "modify skip-modified"

    # 4. New in branch: only in local, never pushed
    _make_change_folder "2601010000-skip-new"

    # Remove folder #2 from origin via a temp clone (simulates it being archived remotely)
    local origin_path tmp_clone
    origin_path=$(git remote get-url origin)
    tmp_clone="${BATS_TEST_TMPDIR}/tmp-clone-skip"
    git clone -q "$origin_path" "$tmp_clone"
    git -C "$tmp_clone" config user.email "test@test.com"
    git -C "$tmp_clone" config user.name "Test"
    git -C "$tmp_clone" rm -r -q "uspecs/changes/2601010000-skip-del-main"
    git -C "$tmp_clone" commit -q -m "delete folder from main"
    git -C "$tmp_clone" push -q origin main

    git fetch -q origin main

    uspecs change archiveall
    [ "$status" -eq 0 ]

    # Only "same" folder remains (unchanged vs origin/main)
    [ -d "$PROJECT_ROOT/uspecs/changes/2601010000-skip-same" ]
    # The other three had modifications -> archived
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2601010000-skip-del-main" ]
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2601010000-skip-modified" ]
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2601010000-skip-new" ]
    [[ "$output" == *"3 archived"* ]]
    [[ "$output" == *"1 unchanged"* ]]
}

@test "change archiveall reports failed count for folders with uncompleted items" {
    cd "$PROJECT_ROOT"

    local folder_name="2601010000-all-todos"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    printf '%s\n' \
        '---' \
        "registered_at: 2026-01-01T00:00:00Z" \
        "change_id: $folder_name" \
        '---' \
        '' \
        '- [ ] uncompleted task' \
        > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"
    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "add $folder_name"

    uspecs change archiveall
    [ "$status" -eq 0 ]
    [ -d "$PROJECT_ROOT/uspecs/changes/$folder_name" ]
    [[ "$output" == *"1 failed"* ]]
}

@test "change archiveall with extra arguments fails" {
    cd "$PROJECT_ROOT"
    _make_change_folder "2601010000-all-extra-arg"

    uspecs change archiveall "2601010000-all-extra-arg"
    [ "$status" -ne 0 ]
}

@test "change archiveall combined with -d fails" {
    cd "$PROJECT_ROOT"

    uspecs change archiveall -d
    [ "$status" -ne 0 ]
}

@test "change archive with --all flag fails" {
    cd "$PROJECT_ROOT"

    uspecs change archive --all
    [ "$status" -ne 0 ]
}
