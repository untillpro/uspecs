# helpers.bash -- shared setup and helpers for uspecs.sh system tests
# Loaded by each per-command .bats file via: load 'helpers'
set -Eeuo pipefail

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
STUBS_DIR="$REPO_ROOT/tests/stubs"

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

    export PROJECT_ROOT="$_tmpdir/project"
    mkdir -p "$PROJECT_ROOT/uspecs"

    # Mirror uspecs/u/ into isolated project root so the script resolves
    # get_project_dir() to $PROJECT_ROOT instead of the real repo root.
    cp -r "$REPO_ROOT/uspecs/u" "$PROJECT_ROOT/uspecs/"
    mkdir -p "$PROJECT_ROOT/uspecs/changes"
    mkdir -p "$PROJECT_ROOT/uspecs/specs"

    # Initialise git repository with main as the default branch.
    cd "$PROJECT_ROOT"
    git -c init.defaultBranch=main init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    git add .
    git commit -q -m "initial commit"

    # Bare repo acts as origin remote.
    local origin_repo="$_tmpdir/origin.git"
    git -c init.defaultBranch=main init -q --bare "$origin_repo"
    (cd "$origin_repo" && git symbolic-ref HEAD refs/heads/main)
    git remote add origin "$origin_repo"
    git push -q origin HEAD:main
    git branch --set-upstream-to=origin/main main

    # Ensure the gh stub is executable and appears first on PATH.
    chmod +x "$STUBS_DIR/gh"
    export PATH="$STUBS_DIR:$PATH"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# uspecs <args>: runs uspecs.sh, merging stderr into stdout so $output covers
# both normal output and error messages.
uspecs() {
    run bash -c 'bash "$1" "${@:2}" 2>&1' -- "$PROJECT_ROOT/uspecs/u/scripts/uspecs.sh" "$@"
}

# _make_change_folder <folder-name>: creates a minimal change folder with no
# uncompleted items and commits it to the current branch.
_make_change_folder() {
    local folder_name="$1"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    printf '%s\n' \
        '---' \
        "registered_at: 2026-01-01T00:00:00Z" \
        "change_id: $folder_name" \
        '---' \
        > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"
    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "add $folder_name"
}

