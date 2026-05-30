# helpers.bash -- shared setup and helpers for softeng.sh system tests
# Loaded by each per-command .bats file via: load 'helpers'
#
# This file is also sourceable outside bats (e.g. by tests/sys/prebuild-templates.sh
# invoked from tests/run-tests.py) so the _build_* helpers can be called to
# pre-populate the template directory before parallel workers start.
set -Eeuo pipefail

# bats_require_minimum_version is defined by bats; guard so the file remains
# sourceable outside a bats run (no-op then).
if declare -F bats_require_minimum_version >/dev/null; then
    bats_require_minimum_version 1.5.0
fi

# Resolve REPO_ROOT / STUBS_DIR from this file's own path so the values are
# identical whether loaded by bats (where BATS_TEST_DIRNAME points at tests/sys)
# or sourced standalone.
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
STUBS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/stubs"

# ---------------------------------------------------------------------------
# Setup / teardown
# ---------------------------------------------------------------------------
#
# Performance note: per-test scaffolding (bin/ mirror + git init + bare origin
# + initial commit + push + upstream) costs ~1.3 s on Windows due to fork
# overhead. We pay that cost once per .bats file by building three lazy
# templates under $BATS_FILE_TMPDIR/_tpl and `cp -a`-cloning the relevant one
# into each test's $PROJECT_ROOT (~0.1 s).
#
#   _tpl/base        bin/ mirror + uspecs/{changes,specs} (no git)
#   _tpl/git         base + .git initialised + initial commit (no origin)
#   _tpl/project     git + remote "origin" set to "../origin.git" (relative)
#   _tpl/origin.git  bare repository with main pre-populated
#
# Templates are built on demand by the _setup_* helpers, so files that don't
# need git pay nothing for the git templates.
#
# When $USPECS_BATS_TPL_DIR is set (e.g. by tests/run-tests.py running tests
# in parallel), templates live at that shared path instead of $BATS_FILE_TMPDIR,
# letting all bats invocations reuse a single pre-built copy.

# Default setup(): cheap work only -- project root mirror and gh stub. Tests
# that need git must call _setup_git_repo (local repo) or _setup_git_origin
# (local repo + bare origin remote) as the first line, or override setup()
# at file scope when every test in the file needs the same level.
setup() {
    _setup_project_root
    _setup_gh_stub
}

# _tpl_dir: emit the template root. When $USPECS_BATS_TPL_DIR is set, use it
# directly (shared across bats invocations, e.g. for parallel runs). Otherwise
# fall back to a per-file location under $BATS_FILE_TMPDIR, mixed-form on
# MSYS/Cygwin so the path agrees with git's view of the filesystem.
_tpl_dir() {
    local _d
    if [[ -n "${USPECS_BATS_TPL_DIR:-}" ]]; then
        _d="$USPECS_BATS_TPL_DIR"
    else
        _d="$BATS_FILE_TMPDIR/_tpl"
    fi
    case "$OSTYPE" in
        msys*|cygwin*) _d=$(cygpath -m "$_d") ;;
    esac
    printf '%s\n' "$_d"
}

# _build_base_template: bin/ mirror + uspecs/{changes,specs}. Idempotent.
_build_base_template() {
    local tpl
    tpl="$(_tpl_dir)/base"
    if [ ! -d "$tpl" ]; then
        mkdir -p "$tpl/uspecs/changes" "$tpl/uspecs/specs"
        cp -r "$REPO_ROOT/bin" "$tpl/bin"
    fi
    printf '%s\n' "$tpl"
}

# _build_git_template: base + .git with an initial commit (no origin remote).
# Idempotent.
_build_git_template() {
    local tpl base
    tpl="$(_tpl_dir)/git"
    if [ ! -d "$tpl/.git" ]; then
        base="$(_build_base_template)"
        cp -a "$base" "$tpl"
        git -C "$tpl" -c init.defaultBranch=main init -q
        git -C "$tpl" config user.email "test@test.com"
        git -C "$tpl" config user.name "Test"
        git -C "$tpl" add .
        git -C "$tpl" commit -q -m "initial commit"
    fi
    printf '%s\n' "$tpl"
}

# _git_with_test_bare_repo_allowed <git> <args...>
# The system-test origin template is an intentional temporary bare repository.
# Some local Git configs set safe.bareRepository=explicit, which rejects
# commands that operate inside that bare fixture. Append a process-scoped Git
# config entry without discarding any GIT_CONFIG_* entries already set by the
# caller.
_git_with_test_bare_repo_allowed() {
    local _count="${GIT_CONFIG_COUNT:-0}"
    if [[ ! "$_count" =~ ^[0-9]+$ ]]; then
        _count=0
    fi
    env \
        "GIT_CONFIG_COUNT=$((_count + 1))" \
        "GIT_CONFIG_KEY_${_count}=safe.bareRepository" \
        "GIT_CONFIG_VALUE_${_count}=all" \
        "$@"
}

# _build_origin_template: build the paired (_tpl/project, _tpl/origin.git)
# templates: a project clone of _tpl/git with `origin` set to "../origin.git"
# (relative, so the pair stays valid when cloned to any sibling location),
# and a bare origin with main pre-populated and tracking configured.
# Idempotent.
_build_origin_template() {
    local d; d="$(_tpl_dir)"
    local proj_tpl="$d/project"
    local origin_tpl="$d/origin.git"
    if [ -d "$proj_tpl/.git" ] && [ -d "$origin_tpl" ]; then
        return 0
    fi
    local git_src; git_src="$(_build_git_template)"
    cp -a "$git_src" "$proj_tpl"
    _git_with_test_bare_repo_allowed git -c init.defaultBranch=main init -q --bare "$origin_tpl"
    _git_with_test_bare_repo_allowed git -C "$origin_tpl" symbolic-ref HEAD refs/heads/main
    # Push via absolute URL first to populate refs/remotes/origin/main and
    # branch.main.{remote,merge}, then rewrite the remote URL to a relative
    # path so the pair is portable to per-test $BATS_TEST_TMPDIR locations.
    git -C "$proj_tpl" remote add origin "$origin_tpl"
    _git_with_test_bare_repo_allowed git -C "$proj_tpl" push -q -u origin HEAD:main
    git -C "$proj_tpl" remote set-url origin "../origin.git"
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
    if [ ! -d "$PROJECT_ROOT" ]; then
        local base; base="$(_build_base_template)"
        cp -a "$base" "$PROJECT_ROOT"
    fi

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
# $PROJECT_ROOT/.git already exists. Implemented by replacing $PROJECT_ROOT
# with a clone of the per-file git template (no per-test git init).
_setup_git_repo() {
    if [ -d "$PROJECT_ROOT/.git" ]; then
        return 0
    fi
    local git_tpl; git_tpl="$(_build_git_template)"
    rm -rf "$PROJECT_ROOT"
    cp -a "$git_tpl" "$PROJECT_ROOT"
    cd "$PROJECT_ROOT"
}

# _setup_git_origin: add a bare origin remote, push main, set upstream.
# Idempotent: no-op if an `origin` remote is already configured. Implemented
# by cloning the paired (_tpl/project, _tpl/origin.git) templates into the
# per-test tmpdir; origin URL is the relative "../origin.git" baked into the
# template, which resolves to the per-test origin.git sibling.
_setup_git_origin() {
    if [ -d "$PROJECT_ROOT/.git" ] \
        && git -C "$PROJECT_ROOT" config --get remote.origin.url >/dev/null; then
        return 0
    fi
    _build_origin_template
    local _tmpdir="$BATS_TEST_TMPDIR"
    case "$OSTYPE" in
        msys*|cygwin*) _tmpdir=$(cygpath -m "$_tmpdir") ;;
    esac
    local d; d="$(_tpl_dir)"
    rm -rf "$PROJECT_ROOT"
    cp -a "$d/project" "$PROJECT_ROOT"
    cp -a "$d/origin.git" "$_tmpdir/origin.git"
    cd "$PROJECT_ROOT"
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
        "change_id: $folder_name" \
        '---' \
        > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"
    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "add $folder_name"
}
