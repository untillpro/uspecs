#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# Helper: assert base AGENT_INSTRUCTIONS output from action uchange
_assert_uchange_base_output() {
    [ "$status" -eq 0 ]
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
}

# --- No options ---

@test "uchange: scn: No options: default branch" {
    # Given Engineer is on <branch>
    # And Git branch <branch_outcome>
    # branch: the default branch
    # branch_outcome: is created with name following branch naming rules
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change

    _assert_uchange_base_output

    # Change folder and change.md created
    local change_folder
    change_folder=$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' | head -1)
    [ -n "$change_folder" ]
    [ -f "$change_folder/change.md" ]

    # Instructions reference the change file
    [[ "$output" == *"change.md"* ]]

    # Instructions contain Why/What section content from artifacts.md
    [[ "$output" == *"Why"* ]]
    [[ "$output" == *"What"* ]]
}

@test "uchange: scn: No options: non-default branch" {
    # Given Engineer is on <branch>
    # And Git branch <branch_outcome>
    # branch: a non-default branch
    # branch_outcome: is not created
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch

    uspecs action uchange --kebab-name my-change

    _assert_uchange_base_output

    # Change folder created
    local change_folder
    change_folder=$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' | head -1)
    [ -n "$change_folder" ]
    [ -f "$change_folder/change.md" ]

    [[ "$output" == *"Why"* ]]
    [[ "$output" == *"What"* ]]
}

# --- Option forwarding ---

@test "uchange: scn: Issue reference provided" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --issue-url "https://github.com/owner/repo/issues/42"

    _assert_uchange_base_output

    # change.md frontmatter contains issue_url
    local change_folder
    change_folder=$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' | head -1)
    [ -n "$change_folder" ]
    grep -q "issue_url:" "$change_folder/change.md"
}

@test "uchange: scn: --no-branch option" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --no-branch

    _assert_uchange_base_output

    # Change folder created, no new branch
    local change_folder
    change_folder=$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' | head -1)
    [ -n "$change_folder" ]
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)
    [ "$current_branch" = "main" ]
}

@test "uchange: scn: --branch option" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch

    uspecs action uchange --kebab-name my-change --branch

    _assert_uchange_base_output

    # --branch forces branch creation even on non-default branch
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)
    [ "$current_branch" = "my-change" ]
}

@test "uchange: scn: --no-impl option" {
    # And ## How section is produced in Change File
    # But uimpl action is not invoked
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --no-impl

    _assert_uchange_base_output
    [[ "$output" == *"Why"* ]]
    [[ "$output" == *"What"* ]]
    [[ "$output" == *'<artdef id="artdef_change_how"'* ]]
    [[ "$output" == *"## How"* ]]
    [[ "$output" != *"- Functional design section"* ]]
}

@test "uchange: --specs creates specs folder and emits FD label" {
    cd "$PROJECT_ROOT"
    rm -rf "$PROJECT_ROOT/uspecs/specs"

    uspecs action uchange --kebab-name my-change --specs

    _assert_uchange_base_output
    # Specs folder created
    [ -d "$PROJECT_ROOT/uspecs/specs" ]
    # FD label and its Required skill pointer emitted in the artdef_impl_all_sections menu
    [[ "$output" == *"- Functional design section"*"Required skill: uspecs-sec-fd"* ]]
}

@test "uchange: without --specs and no specs folder, FD label not emitted" {
    cd "$PROJECT_ROOT"
    rm -rf "$PROJECT_ROOT/uspecs/specs"

    uspecs action uchange --kebab-name my-change

    _assert_uchange_base_output
    # FD label and its Required skill pointer not emitted
    [[ "$output" != *"- Functional design section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-fd"* ]]
}

# --- cmd_change_new internals exercised via action uchange ---

@test "uchange: changes folder auto-creation" {
    cd "$PROJECT_ROOT"
    rm -rf "$PROJECT_ROOT/uspecs/changes"

    uspecs action uchange --kebab-name my-change --no-branch

    _assert_uchange_base_output
    local change_folder
    change_folder=$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' | head -1)
    [ -n "$change_folder" ]
    [ -f "$change_folder/change.md" ]
}

@test "uchange: frontmatter contains change_id" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --no-branch

    _assert_uchange_base_output
    local change_folder
    change_folder=$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' | head -1)
    [ -n "$change_folder" ]
    grep -q "change_id:.*my-change" "$change_folder/change.md"
}

@test "uchange: scn: Issue reference: branch naming" {
    # Then Git branch is created with name <branch_name>
    cd "$PROJECT_ROOT"

    # GitHub URL
    uspecs action uchange --kebab-name my-feature --issue-url "https://github.com/owner/repo/issues/42"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/42-my-feature

    git checkout -q main

    # GitLab URL
    uspecs action uchange --kebab-name add-validation --issue-url "https://gitlab.com/group/project/-/issues/7"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/7-add-validation

    git checkout -q main

    # Jira URL
    uspecs action uchange --kebab-name fix-bug --issue-url "https://jira.example.com/browse/PROJ-123"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/PROJ-123-fix-bug

    git checkout -q main

    # Hash-fragment URL
    uspecs action uchange --kebab-name fix-crash --issue-url "https://example.com/projects/#!766766"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/766766-fix-crash

    git checkout -q main

    # Comment anchor ignored
    uspecs action uchange --kebab-name fix-typo --issue-url "https://github.com/owner/repo/issues/42#issuecomment-123456"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/42-fix-typo

    git checkout -q main

    # No valid issue ID falls back to change name
    uspecs action uchange --kebab-name my-fallback --issue-url "https://example.com/###"
    [ "$status" -eq 0 ]
    git -C "$PROJECT_ROOT" show-ref --verify --quiet refs/heads/my-fallback
}

# --- Edge cases ---

@test "uchange: --kebab-name is required" {
    cd "$PROJECT_ROOT"

    uspecs action uchange

    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"--kebab-name is required"* ]]
}

@test "uchange: scn: --branch and --no-branch are mutually exclusive" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --branch --no-branch

    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"mutually exclusive"* ]]
}

@test "uchange: unknown flag rejected" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --unknown-flag

    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Unknown"* ]]
}

@test "uchange: invalid --kebab-name format rejected" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name "Invalid_Name"

    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"kebab-case"* ]]
}
