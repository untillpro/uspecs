#!/usr/bin/env bats

# E2E tests for: Install uspecs (uspecs/specs/prod/conf/install.feature)
# Requires network access to GitHub. Run on demand, not in every CI step.

CONF_SH="$BATS_TEST_DIRNAME/../../uspecs/u/scripts/conf.sh"

# Ensure git's Unix tools (grep, sed, etc.) take priority over Windows stubs.
case "$OSTYPE" in
    msys*|cygwin*) PATH="/usr/bin:$PATH" ;;
esac


make_git_tmpdir() {
    local tmp_base
    case "$OSTYPE" in
        msys*|cygwin*) tmp_base=$(cygpath -w "$TEMP") ;;
        *)             tmp_base="/tmp" ;;
    esac
    local tmpdir
    tmpdir=$(mktemp -d "$tmp_base/uspecs-e2e.XXXXXX")
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    echo "$tmpdir"
}

# Creates a git repo with a bare origin remote and an initial commit.
make_git_tmpdir_with_origin() {
    local tmpdir
    tmpdir=$(make_git_tmpdir)
    local origin_dir="${tmpdir}-origin.git"
    git -C "$tmpdir" commit -q --allow-empty -m "initial"
    git init -q --bare "$origin_dir"
    git -C "$tmpdir" remote add origin "$origin_dir"
    git -C "$tmpdir" push -q origin HEAD:main
    echo "$tmpdir"
}

# Scenario: Install alpha version
# Uses --local so the current workspace code is installed (no GitHub download lag).
# Verifies uspecs.yml written with commit field and AGENTS.md created.
@test "Alpha install (local, nlia)" {
    local tmpdir
    tmpdir=$(make_git_tmpdir)
    # shellcheck disable=SC2064
    trap 'rm -rf "$tmpdir"' EXIT
    cd "$tmpdir"
    run bash "$CONF_SH" install -y --local --nlia
    [ "$status" -eq 0 ]
    [ -f "$tmpdir/uspecs/u/uspecs.yml" ]
    [ -f "$tmpdir/AGENTS.md" ]
    grep -q "invocation_methods:.*nlia" "$tmpdir/uspecs/u/uspecs.yml"
    grep -qE "^commit: [a-f0-9]{40}" "$tmpdir/uspecs/u/uspecs.yml"
}

# Scenario: Installation failure - working directory is not clean (--pr)
# check_prerequisites in pr.sh ffdefault rejects a dirty working tree.
@test "Install --pr fails when working directory is not clean" {
    local tmpdir
    tmpdir=$(make_git_tmpdir_with_origin)
    # shellcheck disable=SC2064
    trap 'rm -rf "$tmpdir" "${tmpdir}-origin.git"' EXIT
    # Make the working directory dirty
    echo "dirty" > "$tmpdir/dirty.txt"
    # Expose the gh stub so check_prerequisites passes the gh check
    export PATH="$BATS_TEST_DIRNAME/../stubs:$PATH"
    cd "$tmpdir"
    run bash -c "bash '$CONF_SH' install -y --local --nlia --pr 2>&1"
    [ "$status" -ne 0 ]
    echo "$output" | grep -q "uncommitted changes"
}

# Scenario: Installation failure - uspecs already installed
# Verifies exit non-zero and correct error message
@test "Already installed failure" {
    local tmpdir
    tmpdir=$(make_git_tmpdir)
    # shellcheck disable=SC2064
    trap 'rm -rf "$tmpdir"' EXIT
    mkdir -p "$tmpdir/uspecs/u"
    touch "$tmpdir/uspecs/u/uspecs.yml"
    cd "$tmpdir"
    run bash -c "bash '$CONF_SH' install --nlia 2>&1"
    [ "$status" -ne 0 ]
    echo "$output" | grep -q "already installed"
}

