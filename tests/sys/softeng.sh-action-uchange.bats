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

# Helper: assert the split change request artdefs are rendered and the old
# combined artdef is no longer emitted. The What artdef is selected by type:
# `default` asserts `artdef_change_what_default` is emitted and
# `artdef_change_what_fix` is gated out; `fix` asserts the inverse.
_assert_split_change_artdefs_present() {
    local what="${1:-default}"
    [[ "$output" == *'<artdef id="artdef_change_heading"'* ]]
    [[ "$output" == *'<artdef id="artdef_change_why"'* ]]
    if [ "$what" = "fix" ]; then
        [[ "$output" == *'<artdef id="artdef_change_what_fix"'* ]]
        [[ "$output" != *'<artdef id="artdef_change_what_default"'* ]]
    else
        [[ "$output" == *'<artdef id="artdef_change_what_default"'* ]]
        [[ "$output" != *'<artdef id="artdef_change_what_fix"'* ]]
    fi
    [[ "$output" != *'<artdef id="artdef_change_why_what"'* ]]
}

# --- Basic change request creation ---

@test "uchange: scn: Basic change request creation: default branch creates branch" {
    # | branch               | type | branch_outcome                                     |
    # | the default branch   | feat | is created with name following branch naming rules |

    # Given Engineer is on <branch>
    _setup_git_repo

    # When Engineer invokes uchange action with --type <type>
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

    # And Frontmatter has type field set to <type>
    # change_frontmatter artifact carries the supplied --type value
    _assert_frontmatter_contains "type: feat"

    # And Git branch <branch_outcome>
    # Branch directive emitted (default branch + no opt)
    [[ "$output" == *"git checkout -b my-change"* ]]

    # And uimpl action is not invoked automatically
    # Defaults: neither How artdef nor impl-menu bullets emitted
    [[ "$output" != *'<artdef id="artdef_change_how"'* ]]
    [[ "$output" != *"- Functional design section"* ]]
}

@test "uchange: scn: Basic change request creation: non-default branch skips branch creation" {
    # | branch               | type | branch_outcome |
    # | a non-default branch | fix  | is not created |

    # Given Engineer is on <branch>
    _setup_git_repo
    git checkout -q -b feature-branch

    # When Engineer invokes uchange action with --type <type>
    uspecs action uchange --kebab-name my-change --type fix

    _assert_uchange_base_output

    # Then base change request is created with Why and What sections
    # Bash did NOT create the timestamped Change Folder
    [ -z "$(find "$PROJECT_ROOT/uspecs/changes" -maxdepth 1 -type d -name '*-my-change' -print -quit)" ]
    [[ "$output" == *"Why"* ]]
    [[ "$output" == *"What"* ]]
    # Fix-typed invocations emit the fix-specific What artdef and gate out the default
    _assert_split_change_artdefs_present fix

    # And Frontmatter has type field set to <type>
    # change_frontmatter artifact carries the supplied --type value
    _assert_frontmatter_contains "type: fix"

    # And Git branch <branch_outcome>
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

@test "uchange: scn: Domain frontmatter emission" {
    # | exist | instructed |
    # | exist | instructed |

    # Given project domain specifications <exist>
    _setup_git_repo
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"
    touch "$PROJECT_ROOT/uspecs/specs/prod/domain.md"

    # When AI Agent reads uchange action instructions
    uspecs action uchange --kebab-name my-change --type feat

    _assert_uchange_base_output

    # Then AI Agent is <instructed> to scan uspecs/specs/*/domain.md and set "domains" frontmatter field to the list of affected domains
    [[ "$output" == *'<artdef id="artdef_change_domains"'* ]]
    [[ "$output" == *'YAML flow list'* ]]

    # And AI Agent is <instructed> to do best-effort inference of affected domains from the matched directory names when the change input is ambiguous about affected domains
    [[ "$output" == *'best-effort'* ]]

    # And AI Agent is instructed to use relevant domain concepts and terminology while authoring the change request
    [[ "$output" == *use*concepts*terminology*affected*domain* ]]

    # | exist        | instructed     |
    # | do not exist | not instructed |

    # Given project domain specifications <exist>
    rm -rf "$PROJECT_ROOT/uspecs/specs/prod"

    # When AI Agent reads uchange action instructions
    uspecs action uchange --kebab-name my-change --type feat

    _assert_uchange_base_output

    # Then AI Agent is <instructed> to scan uspecs/specs/*/domain.md and set "domains" frontmatter field to the list of affected domains
    [[ "$output" != *'<artdef id="artdef_change_domains"'* ]]
    [[ "$output" != *'@artdef_change_domains'* ]]
    [[ "$output" != *'domains: [prod]'* ]]

    # And AI Agent is <instructed> to do best-effort inference of affected domains from the matched directory names when the change input is ambiguous about affected domains
    [[ "$output" != *'best-effort'* ]]
    [[ "$output" != *'use relevant concepts and terminology from the affected domain specifications'* ]]
}

# --- Issue URLs ---

@test "uchange: scn: Agent is instructed to determine whether issue URL is fetchable" {
    # When AI Agent reads uchange action instructions
    local prompt
    prompt="$(cat "$REPO_ROOT/scripts/templates/actions/uchange.yaml")"

    # Then AI Agent is instructed to check if input contains issue URL
    [[ "$prompt" == *'contains a URL'* ]]

    # And Agent is instructed to pass the URL (if any) as --issue-url option to the softeng.sh
    [[ "$prompt" == *'--issue-url {URL}'* ]]

    # And AI Agent is instructed to pass --fetchable when it can fetch the issue body from that URL
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

    # And Change File body shape is heading, Why and What sections
    _assert_split_change_artdefs_present
    [[ "$output" != *'<artdef id="artdef_change_context"'* ]]

    # Resolves artdef and its ordered instruction line are gated on --fetchable
    [[ "$output" != *'<artdef id="artdef_change_resolves"'* ]]

    # And AI Agent is not instructed to fetch the issue and Issue File is not created
    [[ "$output" != *"Fetch the issue at"* ]]
    # shellcheck disable=SC2016 # literal markdown backticks in expected prompt text
    [[ "$output" != *'Under `--fetchable`'* ]]

    # Issue file artdef is gated on --fetchable, so it must not appear here
    [[ "$output" != *'<artdef id="artdef_issue_file"'* ]]
}

@test "uchange: scn: Issue URL is fetchable" {
    # With --fetchable: issue_url is recorded, fetch directive is emitted, and
    # change.md uses the Resolves + ## Why + ## What shape (no ## Context).
    _setup_git_repo

    uspecs action uchange --kebab-name my-change --type feat \
        --issue-url "https://github.com/owner/repo/issues/42" --fetchable

    _assert_uchange_base_output

    # Then Frontmatter has issue_url value set to the provided issue URL
    _assert_frontmatter_contains "issue_url: https://github.com/owner/repo/issues/42"

    # And Change File body begins with a Resolves: list rendered as a markdown bulleted list before any prose section
    # Resolves artdef presence is asserted in the body-shape block below; bullet
    # ordering is fixed by the line order in `bin/prompts/instr_uchange.md`
    # and not asserted here.

    # And each Resolves entry has the link form "[{issue-number}: {issue-title}](./issue-{issue-number}.md)"
    [[ "$output" == *'- [{issue-number}: {issue-title}](./issue-{issue-number}.md)'* ]]

    # And Change File body continues with Why and What sections
    # Body shape: Resolves + heading/Why/What artdefs rendered, Context and How artdefs absent
    _assert_split_change_artdefs_present
    [[ "$output" == *'<artdef id="artdef_change_resolves"'* ]]
    [[ "$output" != *'<artdef id="artdef_change_context"'* ]]
    [[ "$output" != *'<artdef id="artdef_change_how"'* ]]

    # And AI Agent extracts {issue-number} from --issue-url per its prompt instructions, independently of the bash extractor used for branch naming and Closes #<id>
    [[ "$output" =~ uspecs/changes/[0-9]{10}-my-change/issue-[^/]+\.md ]]

    # And AI Agent is instructed to fetch the issue and save its body to Issue File named issue-{issue-number}.md as markdown
    [[ "$output" == *"Fetch the issue at https://github.com/owner/repo/issues/42"* ]]
    [[ "$output" == *"@artdef_issue_file"* ]]
    [[ "$output" == *'<artdef id="artdef_issue_file"'* ]]

    # And the semantics and per-type guidance for Why and What sections are preserved from the non-fetchable shape
    # Covered by `_assert_split_change_artdefs_present` above: it proves the
    # type-correct What artdef is emitted under --fetchable via the same
    # `(?type_general)` / `(?type_fix)` gates as the non-fetchable shape.
    # Phrase-level assertions on artdef bodies are intentionally omitted to
    # avoid duplicating coverage and to keep the test resilient to routine
    # wording edits in the artdef files.
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
    # plan_requested is set, since constr_maybe mirrors plan_requested)
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

    # | invocation                        |
    # | with default options              |
    # When Engineer invokes uchange action <invocation>
    uspecs action uchange --kebab-name my-change --type feat
    _assert_uchange_base_output
    # Then AI Agent does not invoke self-review
    [[ "$output" != *"self-review"* ]]

    # | invocation                        |
    # | with --how option                 |
    # When Engineer invokes uchange action <invocation>
    uspecs action uchange --kebab-name my-change --type feat --how
    _assert_uchange_base_output
    # Then AI Agent does not invoke self-review
    [[ "$output" != *"self-review"* ]]

    # | invocation                        |
    # | with --fetchable and an issue URL |
    # When Engineer invokes uchange action <invocation>
    uspecs action uchange --kebab-name my-change --type feat \
        --issue-url "https://github.com/owner/repo/issues/42" --fetchable
    _assert_uchange_base_output
    # Then AI Agent does not invoke self-review
    [[ "$output" != *"self-review"* ]]
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
