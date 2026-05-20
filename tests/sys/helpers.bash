# helpers.bash -- shared setup and helpers for softeng.sh system tests
# Loaded by each per-command .bats file via: load 'helpers'
set -Eeuo pipefail

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
STUBS_DIR="$BATS_TEST_DIRNAME/stubs"

# ---------------------------------------------------------------------------
# Setup / teardown
# ---------------------------------------------------------------------------

# Default setup(): cheap work only -- project root mirror and gh stub. Tests
# that need git must call _setup_git_repo (local repo) or _setup_git_origin
# (local repo + bare origin remote) as the first line, or override setup()
# at file scope when every test in the file needs the same level.
setup() {
    _setup_project_root
    _setup_gh_stub
}

# _setup_project_root: mirror bin/ into an isolated $PROJECT_ROOT, create
# uspecs/{changes,specs}, and cd there so tests get a stable cwd even
# without git. Idempotent: safe to call more than once.
_setup_project_root() {
    # On Windows (MSYS/Cygwin), bash /tmp and git /tmp map to different Windows
    # directories. Convert to a mixed Windows path so both agree on the same location.
    local _tmpdir="$BATS_TEST_TMPDIR"
    case "$OSTYPE" in
        msys*|cygwin*) _tmpdir=$(cygpath -m "$_tmpdir") ;;
    esac

    export PROJECT_ROOT="$_tmpdir/project"
    mkdir -p "$PROJECT_ROOT/uspecs"

    # Mirror bin/ into isolated project root so the script resolves
    # get_project_dir() to $PROJECT_ROOT instead of the real repo root.
    if [ ! -d "$PROJECT_ROOT/bin" ]; then
        cp -r "$REPO_ROOT/bin" "$PROJECT_ROOT/"
    fi
    mkdir -p "$PROJECT_ROOT/uspecs/changes"
    mkdir -p "$PROJECT_ROOT/uspecs/specs"

    cd "$PROJECT_ROOT"
}

# _setup_gh_stub: ensure the gh stub is executable and appears first on PATH.
_setup_gh_stub() {
    chmod +x "$STUBS_DIR/gh"
    case ":$PATH:" in
        *":$STUBS_DIR:"*) ;;
        *) export PATH="$STUBS_DIR:$PATH" ;;
    esac
}

# _setup_git_repo: initialise a git repository in $PROJECT_ROOT with main as
# the default branch and an initial commit. Idempotent: no-op if
# $PROJECT_ROOT/.git already exists.
_setup_git_repo() {
    if [ -d "$PROJECT_ROOT/.git" ]; then
        return 0
    fi
    cd "$PROJECT_ROOT"
    git -c init.defaultBranch=main init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    git add .
    git commit -q -m "initial commit"
}

# _setup_git_origin: add a bare origin remote, push main, set upstream.
# Calls _setup_git_repo first so callers may invoke either or both safely.
# Idempotent: no-op if an `origin` remote is already configured.
_setup_git_origin() {
    _setup_git_repo
    if git -C "$PROJECT_ROOT" config --get remote.origin.url >/dev/null; then
        return 0
    fi
    local _tmpdir="$BATS_TEST_TMPDIR"
    case "$OSTYPE" in
        msys*|cygwin*) _tmpdir=$(cygpath -m "$_tmpdir") ;;
    esac
    local origin_repo="$_tmpdir/origin.git"
    git -c init.defaultBranch=main init -q --bare "$origin_repo"
    (cd "$origin_repo" && git symbolic-ref HEAD refs/heads/main)
    git -C "$PROJECT_ROOT" remote add origin "$origin_repo"
    git -C "$PROJECT_ROOT" push -q origin HEAD:main
    git -C "$PROJECT_ROOT" branch --set-upstream-to=origin/main main
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# uspecs <args>: runs softeng.sh with stderr captured separately.
# $output holds stdout; $stderr holds stderr (error messages, git notices, etc.).
uspecs() {
    run --separate-stderr bash "$PROJECT_ROOT/bin/softeng.sh" "$@"
}

# _make_change_folder <folder-name>: creates a minimal change folder with no
# uncompleted items and commits it to the current branch. Callers must have
# run _setup_git_repo (or _setup_git_origin) first, since this helper runs
# `git add` + `git commit`.
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

