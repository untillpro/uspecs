# helpers.bash -- shared setup and helpers for deliver.sh e2e tests
set -Eeuo pipefail

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
case "$OSTYPE" in
    msys*|cygwin*) REPO_ROOT=$(cygpath -m "$REPO_ROOT") ;;
esac

# ---------------------------------------------------------------------------
# Setup / teardown
# ---------------------------------------------------------------------------

setup() {
    # On Windows (MSYS/Cygwin), bash /tmp and git /tmp map to different Windows
    # directories. Convert to a mixed Windows path so both agree on the same location.
    local _tmpdir="$BATS_TEST_TMPDIR"
    case "$OSTYPE" in
        msys*|cygwin*) _tmpdir=$(cygpath -m "$_tmpdir") ;;
    esac

    export MKT_REPO="$_tmpdir/marketplace"
    mkdir -p "$MKT_REPO"

    # Initialise marketplace repo with main as the default branch.
    git -c init.defaultBranch=main init -q "$MKT_REPO"
    git -C "$MKT_REPO" config user.email "test@test.com"
    git -C "$MKT_REPO" config user.name "Test"
    git -C "$MKT_REPO" commit -q --allow-empty -m "initial"

    # Bare repo acts as origin remote so git push works in --release tests.
    local origin_repo="$_tmpdir/mkt-origin.git"
    git -c init.defaultBranch=main init -q --bare "$origin_repo"
    (cd "$origin_repo" && git symbolic-ref HEAD refs/heads/main)
    git -C "$MKT_REPO" remote add origin "$origin_repo"
    git -C "$MKT_REPO" push -q origin HEAD:main
    git -C "$MKT_REPO" branch --set-upstream-to=origin/main main
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# deliver <args>: runs deliver.sh with stderr captured separately.
deliver() {
    run --separate-stderr bash "$REPO_ROOT/scripts/deliver.sh" "$@"
}

# _plugin_version [plugin-folder]: reads the version field from plugin.json
# in MKT_REPO. plugin-folder defaults to "uspecs" (stable); pass "uspecs-dev"
# for dev builds.
_plugin_version() {
    local plugin_folder="${1:-uspecs}"
    python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['version'])" \
        "$MKT_REPO/$plugin_folder/.claude-plugin/plugin.json"
}

# _marketplace_field <python-index-expr>: reads a nested field from
# marketplace.json. Example: _marketplace_field "['owner']['name']"
_marketplace_field() {
    python3 -c "import json,sys; print(json.load(open(sys.argv[1]))$1)" \
        "$MKT_REPO/.claude-plugin/marketplace.json"
}

# _plugin_field <python-index-expr> [plugin-folder]: reads a nested field
# from plugin.json. Example: _plugin_field "['author']['name']"
# plugin-folder defaults to "uspecs"; pass "uspecs-dev" for dev builds.
_plugin_field() {
    local plugin_folder="${2:-uspecs}"
    python3 -c "import json,sys; print(json.load(open(sys.argv[1]))$1)" \
        "$MKT_REPO/$plugin_folder/.claude-plugin/plugin.json"
}

# _core_version: returns the SemVer core (X.Y.Z) read from $REPO_ROOT/version.txt,
# matching the stripping logic in deliver.sh.
_core_version() {
    local raw
    raw="$(tr -d '[:space:]' < "$REPO_ROOT/version.txt")"
    raw="${raw%%-*}"
    raw="${raw%%+*}"
    printf '%s' "$raw"
}

# _commit_count: returns the number of commits on HEAD in MKT_REPO.
_commit_count() {
    git -C "$MKT_REPO" rev-list --count HEAD
}

# _softeng_version [plugin-folder]: reads the USPECS_VERSION literal from
# bin/softeng.sh in MKT_REPO. plugin-folder defaults to "uspecs".
_softeng_version() {
    local plugin_folder="${1:-uspecs}"
    local line
    line="$(grep -m1 '^USPECS_VERSION=' "$MKT_REPO/$plugin_folder/bin/softeng.sh")"
    line="${line#USPECS_VERSION=}"
    line="${line%\"}"
    line="${line#\"}"
    printf '%s' "$line"
}

# _assert_dev_install_block <agent>: asserts README.md install block
# references the dev marketplace consistently for the given agent. The
# expected CLI binary and install subcommand per agent are pinned here so
# the assertion acts as a real oracle independent of the generator's
# AGENT_CONFIGS.
_assert_dev_install_block() {
    local agent="$1"
    local cli install_verb
    case "$agent" in
        claude)  cli="claude"; install_verb="install" ;;
        augment) cli="auggie"; install_verb="install" ;;
        codex)   cli="codex";  install_verb="add" ;;
        *) echo "unknown agent: $agent" >&2; return 1 ;;
    esac
    local market_name="uspecs-dev-plugins-$agent"
    local readme="$MKT_REPO/README.md"
    [[ "$(cat "$readme")" == *"$cli plugin marketplace add uspecs/$market_name"* ]]
    [[ "$(cat "$readme")" == *"$cli plugin $install_verb uspecs-dev@$market_name"* ]]
}
