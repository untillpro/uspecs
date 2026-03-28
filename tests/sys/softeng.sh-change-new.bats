#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

@test "change new: No options, change folder and branch created" {
    cd "$PROJECT_ROOT"
    uspecs change new my-change
    [ "$status" -eq 0 ]
    [[ "$output" == uspecs/changes/[0-9]*-my-change ]]
    [ -d "$PROJECT_ROOT/$output" ]
    [ -f "$PROJECT_ROOT/$output/change.md" ]
    grep -q "change_id:.*my-change" "$PROJECT_ROOT/$output/change.md"
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/my-change
}

@test "change new: No options on non-default branch, branch not created" {
    cd "$PROJECT_ROOT"
    git checkout -b feature-branch
    uspecs change new my-change
    [ "$status" -eq 0 ]
    [[ "$output" == uspecs/changes/[0-9]*-my-change ]]
    # Should stay on feature-branch, no new branch created
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)
    [ "$current_branch" = "feature-branch" ]
    run git show-ref --verify refs/heads/my-change
    [ "$status" -ne 0 ]
}

@test "change new: --branch option on non-default branch, branch created" {
    cd "$PROJECT_ROOT"
    git checkout -b feature-branch
    uspecs change new my-feature --branch
    [ "$status" -eq 0 ]
    git show-ref --verify --quiet refs/heads/my-feature
}

@test "change new: --branch option, branch created" {
    cd "$PROJECT_ROOT"
    uspecs change new my-feature --branch
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/my-feature
}

@test "change new: --no-branch option, branch not created" {
    cd "$PROJECT_ROOT"
    uspecs change new my-change --no-branch
    [ "$status" -eq 0 ]
    run git -C "$PROJECT_ROOT" show-ref --verify refs/heads/my-change
    [ "$status" -ne 0 ]
}

@test "change new: --branch and --no-branch are mutually exclusive" {
    cd "$PROJECT_ROOT"
    uspecs change new my-change --branch --no-branch
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"mutually exclusive"* ]]
}

@test "change new: validation, unknown flag rejected" {
    cd "$PROJECT_ROOT"
    uspecs change new my-change --unknown-flag
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Unknown"* ]]
}

@test "change new: validation, missing change-name rejected" {
    cd "$PROJECT_ROOT"
    uspecs change new
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"change-name is required"* ]]
}

@test "change new: validation, invalid change-name format rejected" {
    cd "$PROJECT_ROOT"
    uspecs change new "Invalid_Name"
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"kebab-case"* ]]
}

@test "change new: Issue reference: branch naming, GitHub URL" {
    cd "$PROJECT_ROOT"
    uspecs change new my-feature --issue-url "https://github.com/owner/repo/issues/42"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/42-my-feature
    grep -q "issue_url: https://github.com/owner/repo/issues/42" "$PROJECT_ROOT/$output/change.md"
}

@test "change new: Issue reference: branch naming, GitLab URL" {
    cd "$PROJECT_ROOT"
    uspecs change new add-validation --issue-url "https://gitlab.com/group/project/-/issues/7"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/7-add-validation
}

@test "change new: Issue reference: branch naming, Jira URL" {
    cd "$PROJECT_ROOT"
    uspecs change new fix-bug --issue-url "https://jira.example.com/browse/PROJ-123"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/PROJ-123-fix-bug
}

@test "change new: Issue reference: branch naming, hash-fragment URL" {
    cd "$PROJECT_ROOT"
    uspecs change new fix-crash --issue-url "https://example.com/projects/#!766766"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/766766-fix-crash
}

@test "change new: Issue reference: branch naming with --no-branch option, branch not created" {
    cd "$PROJECT_ROOT"
    uspecs change new my-change --issue-url "https://github.com/owner/repo/issues/99" --no-branch
    [ "$status" -eq 0 ]
    run git -C "$PROJECT_ROOT" show-ref --verify refs/heads/99-my-change
    [ "$status" -ne 0 ]
}

@test "change new: Issue reference: branch naming, comment anchor ignored for issue ID" {
    cd "$PROJECT_ROOT"
    uspecs change new fix-typo --issue-url "https://github.com/owner/repo/issues/42#issuecomment-123456"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/42-fix-typo
}

@test "change new: Issue reference: branch naming, no valid issue ID falls back to change name" {
    cd "$PROJECT_ROOT"
    uspecs change new my-feature --issue-url "https://example.com/###"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/my-feature
}
