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
    # Action is side-effect-free with respect to the timestamped Change Folder:
    # bash never creates it.
    [[ "$output" =~ uspecs/changes/[0-9]{10}- ]]
}

# Helper: assert that the AGENT_INSTRUCTIONS payload carries a populated
# change_frontmatter artifact whose body contains the given substring.
_assert_frontmatter_contains() {
    local needle="$1"
    [[ "$output" == *'<artifact id="change_frontmatter"'* ]]
    [[ "$output" == *"</artifact>"* ]]
    [[ "$output" == *"$needle"* ]]
}

# --- No options ---

@test "uchange: scn: No options: default branch" {
    # Given Engineer is on <branch>
    # And Git branch <branch_outcome>
    # branch: the default branch
    # branch_outcome: directive to create branch is emitted to the agent
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change

    _assert_uchange_base_output

    # Bash did NOT create the timestamped Change Folder
    [ -z "$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' -print -quit)" ]

    # Instructions reference the change file path that the agent will create
    [[ "$output" =~ uspecs/changes/[0-9]{10}-my-change/change.md ]]

    # Instructions contain Why/What section content from artdefs
    [[ "$output" == *"Why"* ]]
    [[ "$output" == *"What"* ]]

    # Branch directive emitted (default branch + no opt)
    [[ "$output" == *"git checkout -b my-change"* ]]
}

@test "uchange: scn: No options: non-default branch" {
    # Given Engineer is on <branch>
    # And Git branch <branch_outcome>
    # branch: a non-default branch
    # branch_outcome: directive to create branch is NOT emitted
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch

    uspecs action uchange --kebab-name my-change

    _assert_uchange_base_output

    # Bash did NOT create the timestamped Change Folder
    [ -z "$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' -print -quit)" ]

    [[ "$output" == *"Why"* ]]
    [[ "$output" == *"What"* ]]

    # No branch directive
    [[ "$output" != *"git checkout -b"* ]]
}

@test "uchange: scn: No options: detached HEAD" {
    # Given Engineer is on a detached HEAD (common in CI or when checked out
    # at a specific commit) the action must not abort under set -Eeuo pipefail
    # and must skip the branch-creation directive (treated as not-on-default).
    cd "$PROJECT_ROOT"
    git checkout -q --detach HEAD

    uspecs action uchange --kebab-name my-change

    _assert_uchange_base_output

    # No branch directive
    [[ "$output" != *"git checkout -b"* ]]
}

# --- Option forwarding ---

@test "uchange: scn: Issue reference provided" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --issue-url "https://github.com/owner/repo/issues/42"

    _assert_uchange_base_output

    # change_frontmatter artifact carries the issue_url
    _assert_frontmatter_contains "issue_url: https://github.com/owner/repo/issues/42"
}

@test "uchange: scn: --no-branch option" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --no-branch

    _assert_uchange_base_output

    # No branch directive emitted
    [[ "$output" != *"git checkout -b"* ]]

    # Bash leaves the working branch untouched
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)
    [ "$current_branch" = "main" ]
}

@test "uchange: scn: --branch option" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch

    uspecs action uchange --kebab-name my-change --branch

    _assert_uchange_base_output

    # --branch forces the branch directive even from a non-default branch
    [[ "$output" == *"git checkout -b my-change"* ]]

    # Bash does not actually run the checkout
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)
    [ "$current_branch" = "feature-branch" ]
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

# --- bash-side responsibilities exercised via action uchange ---

@test "uchange: changes folder auto-creation" {
    cd "$PROJECT_ROOT"
    rm -rf "$PROJECT_ROOT/uspecs/changes"

    uspecs action uchange --kebab-name my-change --no-branch

    _assert_uchange_base_output
    # Bash creates the parent uspecs/changes/ directory but NOT the timestamped
    # Change Folder; that is the agent's responsibility.
    [ -d "$PROJECT_ROOT/uspecs/changes" ]
    [ -z "$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' -print -quit)" ]
}

@test "uchange: frontmatter artifact contains change_id" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --no-branch

    _assert_uchange_base_output
    _assert_frontmatter_contains "change_id: "
    [[ "$output" =~ change_id:[[:space:]][0-9]{10}-my-change ]]
    _assert_frontmatter_contains "registered_at: "
    _assert_frontmatter_contains "baseline: "
}

@test "uchange: scn: Issue reference: branch naming" {
    # Then a `git checkout -b <branch_name>` directive is emitted to the agent
    cd "$PROJECT_ROOT"

    # GitHub URL
    uspecs action uchange --kebab-name my-feature --issue-url "https://github.com/owner/repo/issues/42"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git checkout -b 42-my-feature"* ]]

    # GitLab URL
    uspecs action uchange --kebab-name add-validation --issue-url "https://gitlab.com/group/project/-/issues/7"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git checkout -b 7-add-validation"* ]]

    # Jira URL
    uspecs action uchange --kebab-name fix-bug --issue-url "https://jira.example.com/browse/PROJ-123"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git checkout -b PROJ-123-fix-bug"* ]]

    # Hash-fragment URL
    uspecs action uchange --kebab-name fix-crash --issue-url "https://example.com/projects/#!766766"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git checkout -b 766766-fix-crash"* ]]

    # Comment anchor ignored
    uspecs action uchange --kebab-name fix-typo --issue-url "https://github.com/owner/repo/issues/42#issuecomment-123456"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git checkout -b 42-fix-typo"* ]]

    # No valid issue ID falls back to change name
    uspecs action uchange --kebab-name my-fallback --issue-url "https://example.com/###"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git checkout -b my-fallback"* ]]
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
