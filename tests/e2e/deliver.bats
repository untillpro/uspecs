#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# ---------------------------------------------------------------------------
# Case 1: --local default (dev) build, per agent
# ---------------------------------------------------------------------------

@test "deliver --local dev build for claude" {
    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --local
    [ "$status" -eq 0 ]
    [[ "$output" == *"Generated claude (--local: no commit, no push)"* ]]
    [[ "$output" == *"Done:"* ]]
    [ -f "$MKT_REPO/uspecs/.claude-plugin/plugin.json" ]
    local ver
    ver="$(_plugin_version)"
    [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+-dev\+[0-9]{8}-[0-9]{4}\.[0-9a-f]{12}$ ]]
    [ "$(_commit_count)" -eq 1 ]
    [ -n "$(git -C "$MKT_REPO" status --porcelain)" ]
}

@test "deliver --local dev build for augment" {
    deliver --agent augment --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --local
    [ "$status" -eq 0 ]
    [[ "$output" == *"Generated augment (--local: no commit, no push)"* ]]
    [[ "$output" == *"Done:"* ]]
    [ -f "$MKT_REPO/uspecs/.claude-plugin/plugin.json" ]
    local ver
    ver="$(_plugin_version)"
    [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+-dev\+[0-9]{8}-[0-9]{4}\.[0-9a-f]{12}$ ]]
    [ "$(_commit_count)" -eq 1 ]
    [ -n "$(git -C "$MKT_REPO" status --porcelain)" ]
}

@test "deliver --local dev build for codex" {
    deliver --agent codex --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --local
    [ "$status" -eq 0 ]
    [[ "$output" == *"Generated codex (--local: no commit, no push)"* ]]
    [[ "$output" == *"Done:"* ]]
    [ -f "$MKT_REPO/uspecs/.claude-plugin/plugin.json" ]
    local ver
    ver="$(_plugin_version)"
    [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+-dev\+[0-9]{8}-[0-9]{4}\.[0-9a-f]{12}$ ]]
    [ "$(_commit_count)" -eq 1 ]
    [ -n "$(git -C "$MKT_REPO" status --porcelain)" ]
}

# ---------------------------------------------------------------------------
# Case 2: --release --local per agent
# ---------------------------------------------------------------------------

@test "deliver --release --local for claude" {
    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release --local
    [ "$status" -eq 0 ]
    local ver
    ver="$(_plugin_version)"
    [ "$ver" = "2.2.0" ]
    [ "$(_commit_count)" -eq 1 ]
    [[ "$output" == *"Done: 2.2.0"* ]]
}

@test "deliver --release --local for augment" {
    deliver --agent augment --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release --local
    [ "$status" -eq 0 ]
    local ver
    ver="$(_plugin_version)"
    [ "$ver" = "2.2.0" ]
    [ "$(_commit_count)" -eq 1 ]
    [[ "$output" == *"Done: 2.2.0"* ]]
}

@test "deliver --release --local for codex" {
    deliver --agent codex --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release --local
    [ "$status" -eq 0 ]
    local ver
    ver="$(_plugin_version)"
    [ "$ver" = "2.2.0" ]
    [ "$(_commit_count)" -eq 1 ]
    [[ "$output" == *"Done: 2.2.0"* ]]
}

# ---------------------------------------------------------------------------
# Case 3: --release --local bypasses skip guardrail
# ---------------------------------------------------------------------------

@test "deliver --release --local regenerates even when version matches and repo is clean" {
    # First establish a clean committed marketplace with matching version
    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release
    [ "$status" -eq 0 ]

    # Now run --local: should regenerate, not skip
    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release --local
    [ "$status" -eq 0 ]
    [[ "$output" != *"Skipping"* ]]
    [[ "$output" == *"Generating claude marketplace"* ]]
    [[ "$output" == *"Generated claude (--local: no commit, no push)"* ]]
}

# ---------------------------------------------------------------------------
# Case 4: argument validation
# ---------------------------------------------------------------------------

@test "deliver fails when --agent is missing" {
    deliver --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --local
    [ "$status" -eq 2 ]
    [[ "${stderr:-}" == *"--agent is required"* ]]
}

@test "deliver fails when --agent is invalid" {
    deliver --agent invalid-agent --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --local
    [ "$status" -eq 2 ]
    [[ "${stderr:-}" == *"must be one of claude|augment|codex"* ]]
}

@test "deliver fails on unknown flag" {
    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --local --unknown-flag
    [ "$status" -eq 2 ]
    [[ "${stderr:-}" == *"unknown argument: --unknown-flag"* ]]
}

# ---------------------------------------------------------------------------
# Case 5: --release skips when version matches and repo is clean
# ---------------------------------------------------------------------------

@test "deliver --release skips on second run when version matches and repo is clean" {
    # First run: generate, commit, push
    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release
    [ "$status" -eq 0 ]
    [ -f "$MKT_REPO/uspecs/.claude-plugin/plugin.json" ]

    # Second run: should skip
    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping claude: already at 2.2.0 and clean"* ]]
    [[ "$output" == *"Done: 2.2.0"* ]]
}

# ---------------------------------------------------------------------------
# Case 6: --release regenerates when version matches but repo is dirty
# ---------------------------------------------------------------------------

@test "deliver --release regenerates when repo is dirty despite version match" {
    # First run: generate, commit, push
    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release
    [ "$status" -eq 0 ]

    # Dirty the working tree
    echo "noise" >> "$MKT_REPO/README.md"

    # Second run: dirty repo prevents skip
    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release
    [ "$status" -eq 0 ]
    [[ "$output" != *"Skipping"* ]]
    [[ "$output" == *"Generating claude marketplace"* ]]
}

# ---------------------------------------------------------------------------
# Case 7: source validation - invalid feature title
# ---------------------------------------------------------------------------

@test "deliver fails when feature title contains invalid YAML plain scalar sequence" {
    # Create a temp copy of the uspecs repo so we can mutate a feature file
    local tmp_repo="$BATS_TEST_TMPDIR/uspecs-invalid-feature"
    cp -r "$REPO_ROOT" "$tmp_repo"
    case "$OSTYPE" in
        msys*|cygwin*) tmp_repo=$(cygpath -m "$tmp_repo") ;;
    esac

    # Inject ': ' into a feature title (invalid in unquoted YAML)
    local feature_file="$tmp_repo/uspecs/specs/prod/softeng/upr.feature"
    sed -i '1s/.*/Feature: Create pull request: from current branch/' "$feature_file"

    deliver --agent claude --uspecs-repo "$tmp_repo" --marketplace-repo "$MKT_REPO" --local
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"feature title contains ': '"* ]]
    [[ "${stderr:-}" == *"Fix the .feature file"* ]]
}
