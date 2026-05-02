#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# ---------------------------------------------------------------------------
# cd.feature: Routing by version.txt -- Pre-release routes to Dev Plugin Repos
# ---------------------------------------------------------------------------

@test "cd: scn: Pre-release version routes to Dev Plugin Repositories: claude" {
    # Then plugin is delivered to "<dev_repo>"
    # And plugin version is "<core>-dev+<TS>.<SHORT_SHA>"
    # agent: claude
    # dev_repo: uspecs/uspecs-dev-plugins-claude
    # core: 2.2.0
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
    _assert_dev_install_block "claude" "claude"
}

@test "cd: scn: Pre-release version routes to Dev Plugin Repositories: augment" {
    # Then plugin is delivered to "<dev_repo>"
    # And plugin version is "<core>-dev+<TS>.<SHORT_SHA>"
    # agent: augment
    # dev_repo: uspecs/uspecs-dev-plugins-augment
    # core: 2.2.0
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
    _assert_dev_install_block "augment" "augment"
}

@test "cd: scn: Pre-release version routes to Dev Plugin Repositories: codex" {
    # Then plugin is delivered to "<dev_repo>"
    # And plugin version is "<core>-dev+<TS>.<SHORT_SHA>"
    # agent: codex
    # dev_repo: uspecs/uspecs-dev-plugins-codex
    # core: 2.2.0
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
    _assert_dev_install_block "codex" "codex"
}

# ---------------------------------------------------------------------------
# cd.feature: Routing by version.txt -- Stable routes to Release Plugin Repos
# ---------------------------------------------------------------------------

@test "cd: scn: Stable version routes to Release Plugin Repositories: claude" {
    # Then plugin is delivered to "<release_repo>"
    # And plugin version is "<version>"
    # agent: claude
    # release_repo: uspecs/uspecs-plugins-claude
    local core
    core="$(_core_version)"
    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release --local
    [ "$status" -eq 0 ]
    local ver
    ver="$(_plugin_version)"
    [ "$ver" = "$core" ]
    [ "$(_commit_count)" -eq 1 ]
    [[ "$output" == *"Done: $core"* ]]
}

@test "cd: scn: Stable version routes to Release Plugin Repositories: augment" {
    # Then plugin is delivered to "<release_repo>"
    # And plugin version is "<version>"
    # agent: augment
    # release_repo: uspecs/uspecs-plugins-augment
    local core
    core="$(_core_version)"
    deliver --agent augment --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release --local
    [ "$status" -eq 0 ]
    local ver
    ver="$(_plugin_version)"
    [ "$ver" = "$core" ]
    [ "$(_commit_count)" -eq 1 ]
    [[ "$output" == *"Done: $core"* ]]
}

@test "cd: scn: Stable version routes to Release Plugin Repositories: codex" {
    # Then plugin is delivered to "<release_repo>"
    # And plugin version is "<version>"
    # agent: codex
    # release_repo: uspecs/uspecs-plugins-codex
    local core
    core="$(_core_version)"
    deliver --agent codex --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release --local
    [ "$status" -eq 0 ]
    local ver
    ver="$(_plugin_version)"
    [ "$ver" = "$core" ]
    [ "$(_commit_count)" -eq 1 ]
    [[ "$output" == *"Done: $core"* ]]
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
    local core
    core="$(_core_version)"

    # First run: generate, commit, push
    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release
    [ "$status" -eq 0 ]
    [ -f "$MKT_REPO/uspecs/.claude-plugin/plugin.json" ]

    # Second run: should skip
    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping claude: already at $core and clean"* ]]
    [[ "$output" == *"Done: $core"* ]]
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

    # Inject ': ' into a feature title (invalid in unquoted YAML).
    # Replace line 1 portably (avoid GNU/BSD `sed -i` differences).
    local feature_file="$tmp_repo/uspecs/specs/prod/softeng/upr.feature"
    {
        echo "Feature: Create pull request: from current branch"
        tail -n +2 "$feature_file"
    } > "$feature_file.tmp"
    mv "$feature_file.tmp" "$feature_file"

    deliver --agent claude --uspecs-repo "$tmp_repo" --marketplace-repo "$MKT_REPO" --local
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"feature title contains ': '"* ]]
    [[ "${stderr:-}" == *"Fix the .feature file"* ]]
}
