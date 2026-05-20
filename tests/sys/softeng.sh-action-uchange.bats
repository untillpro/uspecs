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
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat

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

    # change_frontmatter artifact carries the supplied --type value
    _assert_frontmatter_contains "type: feat"

    # Defaults: neither How artdef nor impl-menu bullets emitted
    [[ "$output" != *'<artdef id="artdef_change_how"'* ]]
    [[ "$output" != *"- Functional design section"* ]]
}

@test "uchange: scn: No options: non-default branch" {
    # Given Engineer is on <branch>
    # And Git branch <branch_outcome>
    # branch: a non-default branch
    # branch_outcome: directive to create branch is NOT emitted
    _setup_git_repo
    git checkout -q -b feature-branch

    uspecs action uchange --kebab-name my-change --type fix

    _assert_uchange_base_output

    # Bash did NOT create the timestamped Change Folder
    [ -z "$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' -print -quit)" ]

    [[ "$output" == *"Why"* ]]
    [[ "$output" == *"What"* ]]

    # No branch directive
    [[ "$output" != *"git checkout -b"* ]]

    # Defaults: neither How artdef nor impl-menu bullets emitted
    [[ "$output" != *'<artdef id="artdef_change_how"'* ]]
    [[ "$output" != *"- Functional design section"* ]]
}

@test "uchange: scn: No options: detached HEAD" {
    # Given Engineer is on a detached HEAD (common in CI or when checked out
    # at a specific commit) the action must not abort under set -Eeuo pipefail
    # and must skip the branch-creation directive (treated as not-on-default).
    _setup_git_repo
    git checkout -q --detach HEAD

    uspecs action uchange --kebab-name my-change --type chore

    _assert_uchange_base_output

    # No branch directive
    [[ "$output" != *"git checkout -b"* ]]
}

# --- Option forwarding ---

@test "uchange: scn: Issue reference provided" {
    # Without --fetchable: issue_url is recorded in frontmatter but no fetch
    # directive is emitted and change.md uses the legacy ## Why + ## What shape.
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat --issue-url "https://github.com/owner/repo/issues/42"

    _assert_uchange_base_output

    # change_frontmatter artifact carries the issue_url
    _assert_frontmatter_contains "issue_url: https://github.com/owner/repo/issues/42"

    # No fetch directive (the AI Agent was not asked to fetch issue.md)
    [[ "$output" != *"Fetch the issue at"* ]]

    # Body shape: legacy Why + What artdef rendered, Context artdef absent
    [[ "$output" == *'<artdef id="artdef_change_why_what"'* ]]
    [[ "$output" != *'<artdef id="artdef_change_context"'* ]]

    # Issue file artdef is gated on --fetchable, so it must not appear here
    [[ "$output" != *'<artdef id="artdef_issue_file"'* ]]
}

@test "uchange: scn: --fetchable with issue reference" {
    # With --fetchable: issue_url is recorded, fetch directive is emitted, and
    # change.md uses the Refs + ## Why + ## What shape (no ## Context).
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat \
        --issue-url "https://github.com/owner/repo/issues/42" --fetchable

    _assert_uchange_base_output

    _assert_frontmatter_contains "issue_url: https://github.com/owner/repo/issues/42"

    # Fetch directive references the issue URL and the change folder's
    # issue-{issue-number}.md file (number extracted by the agent at render
    # time, so the dispatch placeholder pattern is asserted, not a literal id)
    [[ "$output" == *"Fetch the issue at https://github.com/owner/repo/issues/42"* ]]
    [[ "$output" =~ uspecs/changes/[0-9]{10}-my-change/issue-[^/]+\.md ]]

    # Fetch directive references the issue-file artdef
    [[ "$output" == *"@artdef_issue_file"* ]]

    # Body shape: Refs + Why/What artdefs rendered, Context artdef absent
    [[ "$output" == *'<artdef id="artdef_change_why_what"'* ]]
    [[ "$output" == *'<artdef id="artdef_change_refs"'* ]]
    [[ "$output" != *'<artdef id="artdef_change_context"'* ]]

    # Issue file artdef is rendered alongside the fetch directive
    [[ "$output" == *'<artdef id="artdef_issue_file"'* ]]
}

@test "uchange: scn: --fetchable with --how" {
    # With --fetchable --how: in addition to the Refs + Why/What shape, the
    # ## How artdef is rendered and the dispatch instructs the agent to
    # always emit the section.
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat \
        --issue-url "https://github.com/owner/repo/issues/42" --fetchable --how

    _assert_uchange_base_output

    _assert_frontmatter_contains "issue_url: https://github.com/owner/repo/issues/42"

    # Body shape: Refs + Why/What + How artdefs rendered, Context artdef absent
    [[ "$output" == *'<artdef id="artdef_change_why_what"'* ]]
    [[ "$output" == *'<artdef id="artdef_change_refs"'* ]]
    [[ "$output" == *'<artdef id="artdef_change_how"'* ]]
    [[ "$output" != *'<artdef id="artdef_change_context"'* ]]
}

@test "uchange: scn: --fetchable without --how (content-aware How)" {
    # With --fetchable but no --how: the artdef_change_how shape is still
    # rendered so the agent can emit ## How conditionally based on whether
    # the fetched issue describes an approach/design. The dispatch leaves
    # the emission decision to the agent (no hard gate in bash); the
    # content-aware language is present in the rendered instructions.
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat \
        --issue-url "https://github.com/owner/repo/issues/42" --fetchable

    _assert_uchange_base_output

    # Body shape: Refs + Why/What rendered, Context absent
    [[ "$output" == *'<artdef id="artdef_change_why_what"'* ]]
    [[ "$output" == *'<artdef id="artdef_change_refs"'* ]]
    [[ "$output" != *'<artdef id="artdef_change_context"'* ]]

    # artdef_change_how is available to the agent for conditional emission
    [[ "$output" == *'<artdef id="artdef_change_how"'* ]]

    # Dispatch instructions mention the content-aware emission rule so the
    # agent knows ## How is conditional (no hard gate -- decision is on the
    # agent based on the fetched issue content)
    [[ "$output" == *"emit only if"* ]]
    [[ "$output" == *"contains information for the How section"* ]]
}

@test "uchange: scn: --fetchable without issue reference errors out" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --type feat --fetchable

    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"--fetchable requires an issue reference"* ]]
}

@test "uchange: scn: --no-branch option" {
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat --no-branch

    _assert_uchange_base_output

    # No branch directive emitted
    [[ "$output" != *"git checkout -b"* ]]

    # Bash leaves the working branch untouched
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)
    [ "$current_branch" = "main" ]
}

@test "uchange: scn: --branch option" {
    _setup_git_repo
    git checkout -q -b feature-branch

    uspecs action uchange --kebab-name my-change --type feat --branch

    _assert_uchange_base_output

    # --branch forces the branch directive even from a non-default branch
    [[ "$output" == *"git checkout -b my-change"* ]]

    # Bash does not actually run the checkout
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)
    [ "$current_branch" = "feature-branch" ]
}

@test "uchange: scn: --no-impl option is a backwards-compatible no-op" {
    # And the outcome is identical to invocation without the flag
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat
    local out_no_flag="$output"

    uspecs action uchange --kebab-name my-change --type feat --no-impl
    local out_no_impl="$output"

    # Normalize the embedded timestamps so byte-equality holds across second
    # boundaries: timestamped folder name (YYMMDDHHMM-) and the ISO
    # registered_at frontmatter field.
    local norm_no_flag norm_no_impl
    norm_no_flag=$(printf '%s' "$out_no_flag" | sed -E 's/[0-9]{10}-my-change/TIMESTAMP-my-change/g; s/registered_at: [^[:space:]]+/registered_at: TIMESTAMP/')
    norm_no_impl=$(printf '%s' "$out_no_impl" | sed -E 's/[0-9]{10}-my-change/TIMESTAMP-my-change/g; s/registered_at: [^[:space:]]+/registered_at: TIMESTAMP/')

    [ "$norm_no_flag" = "$norm_no_impl" ]
}

@test "uchange: scn: --how option" {
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat --how

    _assert_uchange_base_output
    [[ "$output" == *'<artdef id="artdef_change_how"'* ]]
    [[ "$output" == *"## How"* ]]
    # impl-menu bullets are not emitted
    [[ "$output" != *"- Functional design section"* ]]
    [[ "$output" != *"- Construction and Quick start sections"* ]]
}

@test "uchange: scn: --plan option" {
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat --plan

    _assert_uchange_base_output
    # impl-menu bullets are emitted (Construction is always emitted when
    # impl_maybe is set, since constr_maybe mirrors impl_maybe)
    [[ "$output" == *"- Construction and Quick start sections"* ]]
    # How artdef is not emitted
    [[ "$output" != *'<artdef id="artdef_change_how"'* ]]
}

# ---------------------------------------------------------------------------
# scn: Auto-invoke self-review after uchange --plan
# `uchange --plan` chains a specs self-review (Stage A) with the default
# retry budget of 4. `--no-self-review` suppresses the chain. Variants that
# do not author plan bullets (default, --how, --fetchable) do not chain.
# ---------------------------------------------------------------------------

@test "uchange: --plan chains self-review --type specs --stage A -b 4" {
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat --plan
    _assert_uchange_base_output
    # The chained self-review invocation must use the absolute softeng_sh
    # path (rendered from $_CTX_SCRIPT_DIR) and include the default budget.
    [[ "$output" == *"\"$PROJECT_ROOT/bin/softeng.sh\" self-review --type specs --stage A -b 4"* ]]
}

@test "uchange: --plan --no-self-review suppresses the chain" {
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat --plan --no-self-review
    _assert_uchange_base_output
    # No chained self-review invocation rendered
    [[ "$output" != *"self-review --type specs --stage A"* ]]
}

@test "uchange: without --plan does not chain self-review" {
    _setup_git_repo

    # Default invocation: no plan bullets, no chain
    uspecs action uchange --kebab-name my-change --type feat
    _assert_uchange_base_output
    [[ "$output" != *"self-review --type specs --stage A"* ]]

    # --how alone: no chain
    uspecs action uchange --kebab-name my-change --type feat --how
    _assert_uchange_base_output
    [[ "$output" != *"self-review --type specs --stage A"* ]]

    # --fetchable alone (no --plan): no chain
    uspecs action uchange --kebab-name my-change --type feat \
        --issue-url "https://github.com/owner/repo/issues/42" --fetchable
    _assert_uchange_base_output
    [[ "$output" != *"self-review --type specs --stage A"* ]]
}

@test "uchange: --no-self-review without --plan is accepted as a no-op" {
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat --no-self-review
    _assert_uchange_base_output
    # Flag parses, no error, nothing to suppress
    [[ "$output" != *"self-review --type specs --stage A"* ]]
}

@test "uchange: scn: --no-impl combined with --how" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --type feat --no-impl --how

    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"--no-impl cannot be combined with --how or --plan"* ]]
}

@test "uchange: scn: --no-impl combined with --plan" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --type feat --no-impl --plan

    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"--no-impl cannot be combined with --how or --plan"* ]]
}

@test "uchange: --specs creates specs folder" {
    _setup_git_repo
    rm -rf "$PROJECT_ROOT/uspecs/specs"

    uspecs action uchange --kebab-name my-change --type feat --specs

    _assert_uchange_base_output
    # Specs folder created
    [ -d "$PROJECT_ROOT/uspecs/specs" ]
}

# --- bash-side responsibilities exercised via action uchange ---

@test "uchange: changes folder auto-creation" {
    _setup_git_repo
    rm -rf "$PROJECT_ROOT/uspecs/changes"

    uspecs action uchange --kebab-name my-change --type feat --no-branch

    _assert_uchange_base_output
    # Bash creates the parent uspecs/changes/ directory but NOT the timestamped
    # Change Folder; that is the agent's responsibility.
    [ -d "$PROJECT_ROOT/uspecs/changes" ]
    [ -z "$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' -print -quit)" ]
}

@test "uchange: frontmatter artifact contains change_id" {
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat --no-branch

    _assert_uchange_base_output
    _assert_frontmatter_contains "change_id: "
    [[ "$output" =~ change_id:[[:space:]][0-9]{10}-my-change ]]
    _assert_frontmatter_contains "registered_at: "
    _assert_frontmatter_contains "baseline: "
}

@test "uchange: scn: Issue reference: branch naming" {
    # Then a `git checkout -b <branch_name>` directive is emitted to the agent
    _setup_git_repo

    # GitHub URL
    uspecs action uchange --kebab-name my-feature --type feat --issue-url "https://github.com/owner/repo/issues/42"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git checkout -b 42-my-feature"* ]]

    # GitLab URL
    uspecs action uchange --kebab-name add-validation --type feat --issue-url "https://gitlab.com/group/project/-/issues/7"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git checkout -b 7-add-validation"* ]]

    # Jira URL
    uspecs action uchange --kebab-name fix-bug --type fix --issue-url "https://jira.example.com/browse/PROJ-123"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git checkout -b PROJ-123-fix-bug"* ]]

    # Hash-fragment URL
    uspecs action uchange --kebab-name fix-crash --type fix --issue-url "https://example.com/projects/#!766766"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git checkout -b 766766-fix-crash"* ]]

    # Comment anchor ignored
    uspecs action uchange --kebab-name fix-typo --type fix --issue-url "https://github.com/owner/repo/issues/42#issuecomment-123456"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git checkout -b 42-fix-typo"* ]]

    # No valid issue ID falls back to change name
    uspecs action uchange --kebab-name my-fallback --type feat --issue-url "https://example.com/###"
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

@test "uchange: --type is required" {
    # softeng.sh hard-fails when --type is missing and does NOT enumerate
    # the allowed Conventional Commits types inline. The agent is expected
    # to read the list from the uchange dispatch instructions and surface
    # it to the user.
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change

    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"--type is required"* ]]
    # The error must not enumerate allowed types inline; the canonical
    # list lives in scripts/templates/actions/uchange.yaml only.
    [[ "${stderr:-}" != *"feat"*"fix"* ]]
}

@test "uchange: scn: --branch and --no-branch are mutually exclusive" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --type feat --branch --no-branch

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

    uspecs action uchange --kebab-name "Invalid_Name" --type feat

    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"kebab-case"* ]]
}
