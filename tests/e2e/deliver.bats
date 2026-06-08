#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

_softeng_constant() {
    local name="$1"
    local plugin_folder="${2:-uspecs}"
    local line
    line="$(grep -m1 "^${name}=" "$MKT_REPO/$plugin_folder/bin/_lib/meta.sh")"
    line="${line#"${name}="}"
    line="${line%\"}"
    line="${line#\"}"
    printf '%s' "$line"
}

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
    [ -f "$MKT_REPO/uspecs-dev/.claude-plugin/plugin.json" ]
    [ ! -d "$MKT_REPO/uspecs" ]
    local ver
    ver="$(_plugin_version uspecs-dev)"
    [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+-dev\+[0-9]{8}-[0-9]{4}\.[0-9a-f]{12}$ ]]
    [ "$(_softeng_version uspecs-dev)" = "$ver" ]
    [ "$(_commit_count)" -eq 1 ]
    [ -n "$(git -C "$MKT_REPO" status --porcelain)" ]
    _assert_dev_install_block "claude"
    [ "$(_marketplace_field "['owner']['name']")" = "unTill Software Development Group B.V." ]
    [[ "$(_marketplace_field "['metadata']['description']")" == *"development build"* ]]
    [ "$(_marketplace_field "['metadata']['version']")" = "$ver" ]
    [ "$(_marketplace_field "['plugins'][0]['name']")" = "uspecs-dev" ]
    [ "$(_marketplace_field "['plugins'][0]['source']")" = "./uspecs-dev" ]
    [ "$(_plugin_field "['author']['name']" uspecs-dev)" = "unTill Software Development Group B.V." ]
    [[ "$(_plugin_field "['description']" uspecs-dev)" == *"development build"* ]]
    # uclarify is bundled as a command with body sourced from actions/uclarify.md (file: field)
    [ -f "$MKT_REPO/uspecs-dev/commands/uclarify.md" ]
    [[ "$(cat "$MKT_REPO/uspecs-dev/commands/uclarify.md")" == *"# Clarifications"* ]]
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
    [ -f "$MKT_REPO/uspecs-dev/.claude-plugin/plugin.json" ]
    [ ! -d "$MKT_REPO/uspecs" ]
    local ver
    ver="$(_plugin_version uspecs-dev)"
    [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+-dev\+[0-9]{8}-[0-9]{4}\.[0-9a-f]{12}$ ]]
    [ ! -f "$MKT_REPO/uspecs-dev/bin/uspecs-market.json" ]
    [ "$(_softeng_constant USPECS_MARKETPLACE_REPO uspecs-dev)" = "uspecs/uspecs-dev-plugins-augment" ]
    [ "$(_softeng_constant USPECS_MARKETPLACE_NAME uspecs-dev)" = "uspecs-dev-plugins-augment" ]
    [ "$(_softeng_constant USPECS_STREAM uspecs-dev)" = "development" ]
    [ "$(_softeng_constant USPECS_CLI uspecs-dev)" = "auggie" ]
    [ "$(_softeng_constant USPECS_MARKETPLACE_UPDATE_VERB uspecs-dev)" = "update" ]
    [ "$(_commit_count)" -eq 1 ]
    [ -n "$(git -C "$MKT_REPO" status --porcelain)" ]
    _assert_dev_install_block "augment"
    [ "$(_marketplace_field "['owner']['name']")" = "unTill Software Development Group B.V." ]
    [[ "$(_marketplace_field "['metadata']['description']")" == *"development build"* ]]
    [ "$(_marketplace_field "['metadata']['version']")" = "$ver" ]
    [ "$(_marketplace_field "['plugins'][0]['name']")" = "uspecs-dev" ]
    [ "$(_marketplace_field "['plugins'][0]['source']")" = "./uspecs-dev" ]
    [ "$(_plugin_field "['author']['name']" uspecs-dev)" = "unTill Software Development Group B.V." ]
    [[ "$(_plugin_field "['description']" uspecs-dev)" == *"development build"* ]]
    # Action skill folder name and frontmatter name match the bare action
    [ -f "$MKT_REPO/uspecs-dev/skills/uarchive/SKILL.md" ]
    [[ "$(head -n 5 "$MKT_REPO/uspecs-dev/skills/uarchive/SKILL.md")" == *"name: uarchive"* ]]
    # All action skills opt out of autonomous model invocation
    [[ "$(head -n 5 "$MKT_REPO/uspecs-dev/skills/uarchive/SKILL.md")" == *"disable-model-invocation: true"* ]]
    # uclarify is bundled as a skill with body sourced from actions/uclarify.md (file: field)
    [ -f "$MKT_REPO/uspecs-dev/skills/uclarify/SKILL.md" ]
    [[ "$(head -n 5 "$MKT_REPO/uspecs-dev/skills/uclarify/SKILL.md")" == *"name: uclarify"* ]]
    [[ "$(cat "$MKT_REPO/uspecs-dev/skills/uclarify/SKILL.md")" == *"# Clarifications"* ]]
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
    [ -f "$MKT_REPO/uspecs-dev/.claude-plugin/plugin.json" ]
    [ ! -d "$MKT_REPO/uspecs" ]
    local ver
    ver="$(_plugin_version uspecs-dev)"
    [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+-dev\+[0-9]{8}-[0-9]{4}\.[0-9a-f]{12}$ ]]
    [ "$(_commit_count)" -eq 1 ]
    [ -n "$(git -C "$MKT_REPO" status --porcelain)" ]
    _assert_dev_install_block "codex"
    [ "$(_marketplace_field "['owner']['name']")" = "unTill Software Development Group B.V." ]
    [[ "$(_marketplace_field "['metadata']['description']")" == *"development build"* ]]
    [ "$(_marketplace_field "['metadata']['version']")" = "$ver" ]
    [ "$(_marketplace_field "['plugins'][0]['name']")" = "uspecs-dev" ]
    [ "$(_marketplace_field "['plugins'][0]['source']")" = "./uspecs-dev" ]
    [ "$(_plugin_field "['author']['name']" uspecs-dev)" = "unTill Software Development Group B.V." ]
    [[ "$(_plugin_field "['description']" uspecs-dev)" == *"development build"* ]]
    # Action skill folder name and frontmatter name match the bare action
    [ -f "$MKT_REPO/uspecs-dev/skills/uarchive/SKILL.md" ]
    [[ "$(head -n 5 "$MKT_REPO/uspecs-dev/skills/uarchive/SKILL.md")" == *"name: uarchive"* ]]
    # All action skills opt out of autonomous model invocation
    [[ "$(head -n 5 "$MKT_REPO/uspecs-dev/skills/uarchive/SKILL.md")" == *"disable-model-invocation: true"* ]]
    # uclarify is bundled as a skill with body sourced from actions/uclarify.md (file: field)
    [ -f "$MKT_REPO/uspecs-dev/skills/uclarify/SKILL.md" ]
    [[ "$(head -n 5 "$MKT_REPO/uspecs-dev/skills/uclarify/SKILL.md")" == *"name: uclarify"* ]]
    [[ "$(cat "$MKT_REPO/uspecs-dev/skills/uclarify/SKILL.md")" == *"# Clarifications"* ]]
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
    [ "$(_softeng_version)" = "$core" ]
    [ "$(_commit_count)" -eq 1 ]
    [[ "$output" == *"Done: $core"* ]]
    [ "$(_marketplace_field "['owner']['name']")" = "unTill Software Development Group B.V." ]
    [[ "$(_marketplace_field "['metadata']['description']")" != *"development build"* ]]
    [ "$(_marketplace_field "['metadata']['version']")" = "$core" ]
    [ "$(_marketplace_field "['plugins'][0]['name']")" = "uspecs" ]
    [ "$(_marketplace_field "['plugins'][0]['source']")" = "./uspecs" ]
    [ -f "$MKT_REPO/uspecs/.claude-plugin/plugin.json" ]
    [ ! -d "$MKT_REPO/uspecs-dev" ]
    [ "$(_plugin_field "['author']['name']")" = "unTill Software Development Group B.V." ]
    [[ "$(_plugin_field "['description']")" != *"development build"* ]]
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
    [ ! -f "$MKT_REPO/uspecs/bin/uspecs-market.json" ]
    [ "$(_softeng_constant USPECS_MARKETPLACE_REPO)" = "uspecs/uspecs-plugins-augment" ]
    [ "$(_softeng_constant USPECS_MARKETPLACE_NAME)" = "uspecs-plugins-augment" ]
    [ "$(_softeng_constant USPECS_STREAM)" = "stable" ]
    [ "$(_softeng_constant USPECS_CLI)" = "auggie" ]
    [ "$(_softeng_constant USPECS_MARKETPLACE_UPDATE_VERB)" = "update" ]
    [ "$(_commit_count)" -eq 1 ]
    [[ "$output" == *"Done: $core"* ]]
    [ "$(_marketplace_field "['owner']['name']")" = "unTill Software Development Group B.V." ]
    [[ "$(_marketplace_field "['metadata']['description']")" != *"development build"* ]]
    [ "$(_marketplace_field "['metadata']['version']")" = "$core" ]
    [ "$(_marketplace_field "['plugins'][0]['name']")" = "uspecs" ]
    [ "$(_marketplace_field "['plugins'][0]['source']")" = "./uspecs" ]
    [ -f "$MKT_REPO/uspecs/.claude-plugin/plugin.json" ]
    [ ! -d "$MKT_REPO/uspecs-dev" ]
    [ "$(_plugin_field "['author']['name']")" = "unTill Software Development Group B.V." ]
    [[ "$(_plugin_field "['description']")" != *"development build"* ]]
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
    [ "$(_marketplace_field "['owner']['name']")" = "unTill Software Development Group B.V." ]
    [[ "$(_marketplace_field "['metadata']['description']")" != *"development build"* ]]
    [ "$(_marketplace_field "['metadata']['version']")" = "$core" ]
    [ "$(_marketplace_field "['plugins'][0]['name']")" = "uspecs" ]
    [ "$(_marketplace_field "['plugins'][0]['source']")" = "./uspecs" ]
    [ -f "$MKT_REPO/uspecs/.claude-plugin/plugin.json" ]
    [ ! -d "$MKT_REPO/uspecs-dev" ]
    [ "$(_plugin_field "['author']['name']")" = "unTill Software Development Group B.V." ]
    [[ "$(_plugin_field "['description']")" != *"development build"* ]]
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

# ---------------------------------------------------------------------------
# Case 8: marketplace-repo guard - bootstrap files vs non-bootstrap files
# ---------------------------------------------------------------------------

@test "deliver accepts a marketplace repo bootstrapped with README.md, .gitignore and LICENSE" {
    # Simulate a freshly-created GitHub repo initialised with a README,
    # .gitignore, and LICENSE (typical "create repo" defaults).
    echo "# placeholder" > "$MKT_REPO/README.md"
    printf '*.log\n' > "$MKT_REPO/.gitignore"
    echo "MIT" > "$MKT_REPO/LICENSE"
    git -C "$MKT_REPO" add README.md .gitignore LICENSE
    git -C "$MKT_REPO" commit -q -m "bootstrap"

    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release --local
    [ "$status" -eq 0 ]
    [ -f "$MKT_REPO/uspecs/.claude-plugin/plugin.json" ]
}

@test "deliver refuses to wipe a marketplace repo containing non-bootstrap files" {
    # Anything outside the bootstrap allowlist must block the wipe.
    mkdir -p "$MKT_REPO/src"
    echo "print('hi')" > "$MKT_REPO/src/main.py"

    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --release --local
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"not a recognised marketplace"* ]]
    [[ "${stderr:-}" == *"non-bootstrap files"* ]]
    [[ "${stderr:-}" == *"src"* ]]
}

# ---------------------------------------------------------------------------
# Case 9: relative --uspecs-repo path (matches CI invocation)
# ---------------------------------------------------------------------------

@test "deliver accepts a relative --uspecs-repo path" {
    # Regression: read_action_options passed a relative softeng.sh path to
    # bash while also setting cwd=source, causing bash to look for
    # <repo>/<repo>/bin/softeng.sh. CI hits this because it invokes
    # `bash uspecs/scripts/deliver.sh --uspecs-repo uspecs ...`.
    local parent base
    parent="$(dirname "$REPO_ROOT")"
    base="$(basename "$REPO_ROOT")"
    run --separate-stderr bash -c \
        "cd '$parent' && bash '$REPO_ROOT/scripts/deliver.sh' \
            --agent augment --uspecs-repo '$base' \
            --marketplace-repo '$MKT_REPO' --local"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Generated augment (--local: no commit, no push)"* ]]
    [ -f "$MKT_REPO/uspecs-dev/.claude-plugin/plugin.json" ]
}

# ---------------------------------------------------------------------------
# Shared skill content transclusion
# (devops Domain architecture: Shared skill content)
# ---------------------------------------------------------------------------

@test "shared content is inlined and the shared source is excluded from output" {
    deliver --agent claude --uspecs-repo "$REPO_ROOT" --marketplace-repo "$MKT_REPO" --local
    [ "$status" -eq 0 ]
    local skills="$MKT_REPO/uspecs-dev/skills"

    # Shared to-do format content is inlined into a consuming skill...
    local skill="$skills/uspecs-sec-fd/SKILL.md"
    [ -f "$skill" ]
    [[ "$(cat "$skill")" == *"Follow the to-do list format"* ]]

    # ...the uspecs-concepts/shared source is absent from the output...
    [ ! -d "$skills/uspecs-concepts/shared" ]

    # ...and no shared-content link remains in any published skill file.
    run grep -r "uspecs-concepts/shared/" "$skills"
    [ -z "$output" ]
}

@test "deliver fails when a skill references a missing shared snippet" {
    # Create a temp copy of the uspecs repo so we can mutate a skill file
    local tmp_repo="$BATS_TEST_TMPDIR/uspecs-missing-shared"
    cp -r "$REPO_ROOT" "$tmp_repo"
    case "$OSTYPE" in
        msys*|cygwin*) tmp_repo=$(cygpath -m "$tmp_repo") ;;
    esac

    # Point a knowledge skill at a shared snippet that does not exist.
    local skill="$tmp_repo/.claude/skills/uspecs-sec-fd/SKILL.md"
    printf '\n[broken](../uspecs-concepts/shared/does-not-exist.md)\n' >> "$skill"

    deliver --agent claude --uspecs-repo "$tmp_repo" --marketplace-repo "$MKT_REPO" --local
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"does-not-exist.md"* ]]
    [[ "${stderr:-}" == *"not found"* ]]
}