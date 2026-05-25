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

# --- Basic change request creation ---

@test "uchange: scn: Basic change request creation: default branch creates branch" {
    # Given Engineer is on <branch>
    # branch: the default branch
    _setup_git_repo

    # type: feat
    uspecs action uchange --kebab-name my-change --type feat

    _assert_uchange_base_output

    # Then base change request is created with Why and What sections
    # Bash did NOT create the timestamped Change Folder
    [ -z "$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' -print -quit)" ]

    # Instructions reference the change file path that the agent will create
    [[ "$output" =~ uspecs/changes/[0-9]{10}-my-change/change.md ]]

    # Instructions contain Why/What section content from artdefs
    [[ "$output" == *"Why"* ]]
    [[ "$output" == *"What"* ]]

    # And Git branch <branch_outcome>
    # branch_outcome: directive to create branch is emitted to the agent
    # Branch directive emitted (default branch + no opt)
    [[ "$output" == *"git checkout -b my-change"* ]]

    # And Frontmatter has type field set to <type>
    # change_frontmatter artifact carries the supplied --type value
    _assert_frontmatter_contains "type: feat"

    # And uimpl action is not invoked automatically
    # Defaults: neither How artdef nor impl-menu bullets emitted
    [[ "$output" != *'<artdef id="artdef_change_how"'* ]]
    [[ "$output" != *"- Functional design section"* ]]
}

@test "uchange: scn: Basic change request creation: non-default branch skips branch creation" {
    # Given Engineer is on <branch>
    # branch: a non-default branch
    _setup_git_repo
    git checkout -q -b feature-branch

    # type: fix
    uspecs action uchange --kebab-name my-change --type fix

    _assert_uchange_base_output

    # Then base change request is created with Why and What sections
    # Bash did NOT create the timestamped Change Folder
    [ -z "$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' -print -quit)" ]

    [[ "$output" == *"Why"* ]]
    [[ "$output" == *"What"* ]]

    # And Git branch <branch_outcome>
    # branch_outcome: directive to create branch is NOT emitted
    # No branch directive
    [[ "$output" != *"git checkout -b"* ]]

    # And uimpl action is not invoked automatically
    # Defaults: neither How artdef nor impl-menu bullets emitted
    [[ "$output" != *'<artdef id="artdef_change_how"'* ]]
    [[ "$output" != *"- Functional design section"* ]]
}

@test "uchange: detached HEAD skips branch directive" {
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

# --- Issue URLs ---

@test "uchange: scn: Agent is instructed to determine whether issue URL is fetchable" {
    local prompt
    prompt="$(cat "$REPO_ROOT/scripts/templates/actions/uchange.yaml")"

    # Then AI Agent is instructed to pass --issue-url {URL}
    [[ "$prompt" == *'--issue-url {URL}'* ]]

    # And AI Agent is instructed to also pass --fetchable when it can fetch the issue body from that URL
    [[ "$prompt" == *'--fetchable'* ]]
    [[ "$prompt" == *'fetch the issue body'* ]]
}

@test "uchange: scn: Issue URL is not fetchable" {
    # Without --fetchable: issue_url is recorded in frontmatter but no fetch
    # directive is emitted and change.md uses the legacy ## Why + ## What shape.
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat --issue-url "https://github.com/owner/repo/issues/42"

    _assert_uchange_base_output

    # Then Frontmatter has issue_url value set to the provided issue URL
    _assert_frontmatter_contains "issue_url: https://github.com/owner/repo/issues/42"

    # And Change File body shape is Why and What sections
    [[ "$output" == *'<artdef id="artdef_change_why_what"'* ]]
    [[ "$output" != *'<artdef id="artdef_change_context"'* ]]

    # Refs artdef and the "Insert Refs:" rule are gated on --fetchable
    [[ "$output" != *'<artdef id="artdef_change_refs"'* ]]
    [[ "$output" != *"Insert the "*"Refs:"*"block"* ]]

    # And AI Agent is not instructed to fetch the issue and Issue File is not created
    [[ "$output" != *"Fetch the issue at"* ]]

    # Issue file artdef is gated on --fetchable, so it must not appear here
    [[ "$output" != *'<artdef id="artdef_issue_file"'* ]]
}

@test "uchange: scn: Issue URL is fetchable" {
    # With --fetchable: issue_url is recorded, fetch directive is emitted, and
    # change.md uses the Refs + ## Why + ## What shape (no ## Context).
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat \
        --issue-url "https://github.com/owner/repo/issues/42" --fetchable

    _assert_uchange_base_output

    # Then Frontmatter has issue_url value set to the provided issue URL
    _assert_frontmatter_contains "issue_url: https://github.com/owner/repo/issues/42"

    # And Change File body begins with a Refs section rendered as a markdown bulleted list before any prose section
    [[ "$output" == *'Refs:'* ]]
    [[ "$output" == *'Insert the `Refs:` block from `@artdef_change_refs` between the H1 and `## Why`'* ]]

    # And each Refs entry has the link form "[{issue-number}: {issue-title}](./issue-{issue-number}.md)"
    [[ "$output" == *'- [{issue-number}: {issue-title}](./issue-{issue-number}.md)'* ]]

    # And Change File body continues with Why and What sections
    # Body shape: Refs + Why/What artdefs rendered, Context artdef absent
    [[ "$output" == *'<artdef id="artdef_change_why_what"'* ]]
    [[ "$output" == *'<artdef id="artdef_change_refs"'* ]]
    [[ "$output" != *'<artdef id="artdef_change_context"'* ]]

    # And AI Agent extracts {issue-number} from --issue-url per its prompt instructions, independently of the bash extractor used for branch naming and Closes #<id>
    [[ "$output" =~ uspecs/changes/[0-9]{10}-my-change/issue-[^/]+\.md ]]

    # And AI Agent is instructed to fetch the issue and save its body to Issue File named issue-{issue-number}.md as markdown
    [[ "$output" == *"Fetch the issue at https://github.com/owner/repo/issues/42"* ]]
    [[ "$output" == *"@artdef_issue_file"* ]]
    [[ "$output" == *'<artdef id="artdef_issue_file"'* ]]

    # And Why and What sections in Change File are populated by AI Agent by distilling the fetched issue in the change's terms, not by verbatim restatement
    [[ "$output" == *'distilling the fetched issue'* ]]
    [[ "$output" == *'do not restate the issue body verbatim'* ]]

    # And the semantics and per-type guidance for Why and What sections are preserved from the non-fetchable shape
    [[ "$output" == *'Tailor the `## What` items to the `type:` frontmatter value'* ]]
}

@test "uchange: scn: ## How section under --fetchable: --how always emits How" {
    # how_flag: --how
    # approach_in_issue: describes an approach, does not describe an approach
    # With --fetchable --how: in addition to the Refs + Why/What shape, the
    # ## How artdef is rendered and the dispatch instructs the agent to
    # always emit the section.
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat \
        --issue-url "https://github.com/owner/repo/issues/42" --fetchable --how

    _assert_uchange_base_output

    _assert_frontmatter_contains "issue_url: https://github.com/owner/repo/issues/42"

    # Then ## How section <how_outcome> in Change File
    # how_outcome: is produced
    # Body shape: Refs + Why/What + How artdefs rendered, Context artdef absent
    [[ "$output" == *'<artdef id="artdef_change_why_what"'* ]]
    [[ "$output" == *'<artdef id="artdef_change_refs"'* ]]
    [[ "$output" == *'<artdef id="artdef_change_how"'* ]]
    [[ "$output" != *'<artdef id="artdef_change_context"'* ]]
}

@test "uchange: scn: ## How section under --fetchable: omitted --how uses issue-content gate" {
    # how_flag: (omitted)
    # approach_in_issue: describes an approach, does not describe an approach
    # With --fetchable but no --how: the artdef_change_how shape is still
    # rendered so the agent can emit ## How conditionally based on whether
    # the fetched issue describes an approach/design. The dispatch leaves
    # the emission decision to the agent (no hard gate in bash); the
    # content-aware language is present in the rendered instructions.
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat \
        --issue-url "https://github.com/owner/repo/issues/42" --fetchable

    _assert_uchange_base_output

    # Then ## How section <how_outcome> in Change File
    # how_outcome: is produced only when issue content contains How information
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

@test "uchange: scn: error: --fetchable without an issue URL" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --type feat --fetchable

    # And change request is not created
    [ "$status" -ne 0 ]

    # Then error is displayed: "--fetchable requires an issue URL"
    [[ "${stderr:-}" == *"--fetchable requires an issue URL"* ]]
}

@test "uchange: scn: --no-branch option" {
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat --no-branch

    # Then base change request is created
    _assert_uchange_base_output

    # And Git branch is not created
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

    # Then base change request is created
    _assert_uchange_base_output

    # And Git branch is created with name following branch naming rules
    # --branch forces the branch directive even from a non-default branch
    [[ "$output" == *"git checkout -b my-change"* ]]

    # Bash does not actually run the checkout
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)
    [ "$current_branch" = "feature-branch" ]
}

@test "uchange: scn: --no-impl option is a backwards-compatible no-op" {
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat
    local out_no_flag="$output"

    uspecs action uchange --kebab-name my-change --type feat --no-impl
    local out_no_impl="$output"

    # Normalize the timestamped folder name (YYMMDDHHMM-) so byte-equality
    # holds across second boundaries.
    local norm_no_flag norm_no_impl
    norm_no_flag=$(printf '%s' "$out_no_flag" | sed -E 's/[0-9]{10}-my-change/TIMESTAMP-my-change/g')
    norm_no_impl=$(printf '%s' "$out_no_impl" | sed -E 's/[0-9]{10}-my-change/TIMESTAMP-my-change/g')

    # Then the outcome is identical to invocation without the flag
    [ "$norm_no_flag" = "$norm_no_impl" ]
}

@test "uchange: scn: --how option forces How section creation" {
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat --how

    # Then base change request is created
    _assert_uchange_base_output

    # And How section is produced in Change File
    [[ "$output" == *'<artdef id="artdef_change_how"'* ]]
    [[ "$output" == *"## How"* ]]

    # And uimpl action is not invoked automatically
    # impl-menu bullets are not emitted
    [[ "$output" != *"- Functional design section"* ]]
    [[ "$output" != *"- Construction and Quick start sections"* ]]
}

@test "uchange: scn: --plan option" {
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat --plan

    # Then base change request is created
    _assert_uchange_base_output

    # And uimpl action is invoked automatically
    # impl-menu bullets are emitted (Construction is always emitted when
    # impl_maybe is set, since constr_maybe mirrors impl_maybe)
    [[ "$output" == *"- Construction and Quick start sections"* ]]
    # How artdef is not emitted
    [[ "$output" != *'<artdef id="artdef_change_how"'* ]]
}

# ---------------------------------------------------------------------------
# Auto-invoke self-review after uchange --plan
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

@test "uchange: scn: uchange without --plan does not chain self-review: default, --how, fetchable" {
    _setup_git_repo

    # invocation: with default options
    # Default invocation: no plan bullets, no chain
    uspecs action uchange --kebab-name my-change --type feat
    _assert_uchange_base_output
    # Then AI Agent does not invoke self-review
    [[ "$output" != *"self-review --type specs --stage A"* ]]

    # invocation: with --how option
    # --how alone: no chain
    uspecs action uchange --kebab-name my-change --type feat --how
    _assert_uchange_base_output
    # Then AI Agent does not invoke self-review
    [[ "$output" != *"self-review --type specs --stage A"* ]]

    # invocation: with --fetchable and an issue URL
    # --fetchable alone (no --plan): no chain
    uspecs action uchange --kebab-name my-change --type feat \
        --issue-url "https://github.com/owner/repo/issues/42" --fetchable
    _assert_uchange_base_output
    # Then AI Agent does not invoke self-review
    [[ "$output" != *"self-review --type specs --stage A"* ]]
}

@test "uchange: --no-self-review without --plan is accepted as a no-op" {
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat --no-self-review
    _assert_uchange_base_output
    # Flag parses, no error, nothing to suppress
    [[ "$output" != *"self-review --type specs --stage A"* ]]
}

@test "uchange: scn: --no-impl combined with --how or --plan: --how" {
    # other: --how
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --type feat --no-impl --how

    # And change request is not created
    [ "$status" -ne 0 ]

    # Then error is displayed: "--no-impl cannot be combined with --how or --plan"
    [[ "${stderr:-}" == *"--no-impl cannot be combined with --how or --plan"* ]]
}

@test "uchange: scn: --no-impl combined with --how or --plan: --plan" {
    # other: --plan
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --type feat --no-impl --plan

    # And change request is not created
    [ "$status" -ne 0 ]

    # Then error is displayed: "--no-impl cannot be combined with --how or --plan"
    [[ "${stderr:-}" == *"--no-impl cannot be combined with --how or --plan"* ]]
}

@test "uchange: scn: --specs option" {
    _setup_git_repo
    rm -rf "$PROJECT_ROOT/uspecs/specs"

    uspecs action uchange --kebab-name my-change --type feat --specs

    # Then base change request is created
    _assert_uchange_base_output

    # And specs folder is created if it does not exist
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
}

@test "uchange: scn: Issue URL: branch naming" {
    _setup_git_repo

    # | issue_url                                   | change_name    | branch_name      |
    # | https://github.com/owner/repo/issues/42     | my-feature     | 42-my-feature    |
    uspecs action uchange --kebab-name my-feature --type feat --issue-url "https://github.com/owner/repo/issues/42"
    [ "$status" -eq 0 ]
    # Then Git branch is created with name <branch_name>
    [[ "$output" == *"git checkout -b 42-my-feature"* ]]

    # | issue_url                                   | change_name    | branch_name      |
    # | https://gitlab.com/group/project/-/issues/7 | add-validation | 7-add-validation |
    uspecs action uchange --kebab-name add-validation --type feat --issue-url "https://gitlab.com/group/project/-/issues/7"
    [ "$status" -eq 0 ]
    # Then Git branch is created with name <branch_name>
    [[ "$output" == *"git checkout -b 7-add-validation"* ]]

    # | issue_url                                   | change_name    | branch_name      |
    # | https://jira.example.com/browse/PROJ-123    | fix-bug        | PROJ-123-fix-bug |
    uspecs action uchange --kebab-name fix-bug --type fix --issue-url "https://jira.example.com/browse/PROJ-123"
    [ "$status" -eq 0 ]
    # Then Git branch is created with name <branch_name>
    [[ "$output" == *"git checkout -b PROJ-123-fix-bug"* ]]

    # | issue_url                                   | change_name    | branch_name      |
    # | https://example.com/projects/#!766766       | fix-crash      | 766766-fix-crash |
    uspecs action uchange --kebab-name fix-crash --type fix --issue-url "https://example.com/projects/#!766766"
    [ "$status" -eq 0 ]
    # Then Git branch is created with name <branch_name>
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

@test "uchange: scn: --type option is missing" {
    # softeng.sh hard-fails when --type is missing and does NOT enumerate
    # the allowed Conventional Commits types inline. The agent is expected
    # to read the list from the uchange dispatch instructions and surface
    # it to the user.
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change

    # And change request is not created
    [ "$status" -ne 0 ]

    # Then error is displayed indicating --type is required and AI Agent is instructed to read the allowed Conventional Commits types from the uchange dispatch instructions and present them to the Engineer
    [[ "${stderr:-}" == *"--type is required"* ]]
    # The error must not enumerate allowed types inline; the canonical
    # list lives in scripts/templates/actions/uchange.yaml only.
    [[ "${stderr:-}" != *"feat"*"fix"* ]]
}

@test "uchange: scn: --branch and --no-branch are mutually exclusive" {
    cd "$PROJECT_ROOT"

    uspecs action uchange --kebab-name my-change --type feat --branch --no-branch

    # And change request is not created
    [ "$status" -ne 0 ]

    # Then error is displayed: "--branch and --no-branch are mutually exclusive"
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
