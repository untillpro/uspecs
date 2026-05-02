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

# _plugin_version: reads the version field from plugin.json in MKT_REPO.
_plugin_version() {
    python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['version'])" \
        "$MKT_REPO/uspecs/.claude-plugin/plugin.json"
}

# _commit_count: returns the number of commits on HEAD in MKT_REPO.
_commit_count() {
    git -C "$MKT_REPO" rev-list --count HEAD
}
