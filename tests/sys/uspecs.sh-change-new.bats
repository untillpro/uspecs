#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

@test "change new creates change folder and change.md" {
    cd "$PROJECT_ROOT"
    uspecs change new my-change
    [ "$status" -eq 0 ]
    [[ "$output" == uspecs/changes/[0-9]*-my-change ]]
    [ -d "$PROJECT_ROOT/$output" ]
    [ -f "$PROJECT_ROOT/$output/change.md" ]
    grep -q "change_id:.*my-change" "$PROJECT_ROOT/$output/change.md"
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/my-change
}

@test "change new --branch creates git branch" {
    cd "$PROJECT_ROOT"
    uspecs change new my-feature --branch
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/my-feature
}

@test "change new --no-branch does not create branch" {
    cd "$PROJECT_ROOT"
    uspecs change new my-change --no-branch
    [ "$status" -eq 0 ]
    run git -C "$PROJECT_ROOT" show-ref --verify refs/heads/my-change
    [ "$status" -ne 0 ]
}

@test "change new --branch and --no-branch fails with error" {
    cd "$PROJECT_ROOT"
    uspecs change new my-change --branch --no-branch
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"mutually exclusive"* ]]
}

@test "change new with unknown flag fails" {
    cd "$PROJECT_ROOT"
    uspecs change new my-change --unknown-flag
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Unknown"* ]]
}

@test "change new with missing change-name fails" {
    cd "$PROJECT_ROOT"
    uspecs change new
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"change-name is required"* ]]
}

@test "change new with invalid change-name format fails" {
    cd "$PROJECT_ROOT"
    uspecs change new "Invalid_Name"
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"kebab-case"* ]]
}

@test "change new with GitHub issue URL creates branch with issue-id prefix" {
    cd "$PROJECT_ROOT"
    uspecs change new my-feature --issue-url "https://github.com/owner/repo/issues/42"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/42-my-feature
    grep -q "issue_url: https://github.com/owner/repo/issues/42" "$PROJECT_ROOT/$output/change.md"
}

@test "change new with GitLab issue URL creates branch with issue-id prefix" {
    cd "$PROJECT_ROOT"
    uspecs change new add-validation --issue-url "https://gitlab.com/group/project/-/issues/7"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/7-add-validation
}

@test "change new with Jira issue URL creates branch with issue-id prefix" {
    cd "$PROJECT_ROOT"
    uspecs change new fix-bug --issue-url "https://jira.example.com/browse/PROJ-123"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/PROJ-123-fix-bug
}

@test "change new with hash-fragment issue URL creates branch with issue-id prefix" {
    cd "$PROJECT_ROOT"
    uspecs change new fix-crash --issue-url "https://example.com/projects/#!766766"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/766766-fix-crash
}

@test "change new with issue URL and --no-branch does not create branch" {
    cd "$PROJECT_ROOT"
    uspecs change new my-change --issue-url "https://github.com/owner/repo/issues/99" --no-branch
    [ "$status" -eq 0 ]
    run git -C "$PROJECT_ROOT" show-ref --verify refs/heads/99-my-change
    [ "$status" -ne 0 ]
}
