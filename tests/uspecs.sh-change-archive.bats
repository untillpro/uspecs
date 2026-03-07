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
    ! git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/my-feature--pr
}

