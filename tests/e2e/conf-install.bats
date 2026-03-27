#!/usr/bin/env bats

# E2E tests for: Install uspecs (uspecs/specs/prod/conf/install.feature)
# Requires network access to GitHub. Run on demand, not in every CI step.

CONF_SH="$BATS_TEST_DIRNAME/../../uspecs/u/scripts/conf.sh"

# Ensure git's Unix tools (grep, sed, etc.) take priority over Windows stubs.
case "$OSTYPE" in
    msys*|cygwin*) PATH="/usr/bin:$PATH" ;;
esac


make_temp_repo() {
    # On Windows, bash /tmp and git /tmp differ; use cygpath for agreement.
    local _tmpdir="$BATS_TEST_TMPDIR"
    case "$OSTYPE" in
        msys*|cygwin*) _tmpdir=$(cygpath -m "$_tmpdir") ;;
    esac
    local tmpdir="$_tmpdir/repo"
    mkdir -p "$tmpdir"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    echo "$tmpdir"
}

# Creates a git repo with a bare origin remote and an initial commit.
make_temp_repo_with_origin() {
    local tmpdir
    tmpdir=$(make_temp_repo)
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
    tmpdir=$(make_temp_repo)
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
    tmpdir=$(make_temp_repo_with_origin)
    # Make the working directory dirty
    echo "dirty" > "$tmpdir/dirty.txt"
    # Expose the gh stub so check_prerequisites passes the gh check
    export PATH="$BATS_TEST_DIRNAME/../stubs:$PATH"
    cd "$tmpdir"
    run bash -c "bash '$CONF_SH' install -y --local --nlia --pr 2>&1"
    [ "$status" -ne 0 ]
    echo "$output" | grep -q "uncommitted changes"
}

# Scenario: Install alpha version with nlic
# Uses --local so the current workspace code is installed (no GitHub download lag).
# Verifies uspecs.yml written with commit field and CLAUDE.md created.
@test "Alpha install (local, nlic)" {
    local tmpdir
    tmpdir=$(make_temp_repo)
    cd "$tmpdir"
    run bash "$CONF_SH" install -y --local --nlic
    [ "$status" -eq 0 ]
    [ -f "$tmpdir/uspecs/u/uspecs.yml" ]
    [ -f "$tmpdir/CLAUDE.md" ]
    grep -q "invocation_methods:.*nlic" "$tmpdir/uspecs/u/uspecs.yml"
    grep -qE "^commit: [a-f0-9]{40}" "$tmpdir/uspecs/u/uspecs.yml"
}

# Scenario: Install alpha version with both nlia and nlic
# Uses --local so the current workspace code is installed (no GitHub download lag).
# Verifies both AGENTS.md and CLAUDE.md created and metadata lists both methods.
@test "Alpha install (local, nlia + nlic)" {
    local tmpdir
    tmpdir=$(make_temp_repo)
    cd "$tmpdir"
    run bash "$CONF_SH" install -y --local --nlia --nlic
    [ "$status" -eq 0 ]
    [ -f "$tmpdir/uspecs/u/uspecs.yml" ]
    [ -f "$tmpdir/AGENTS.md" ]
    [ -f "$tmpdir/CLAUDE.md" ]
    grep -q "invocation_methods:.*nlia" "$tmpdir/uspecs/u/uspecs.yml"
    grep -q "invocation_methods:.*nlic" "$tmpdir/uspecs/u/uspecs.yml"
    grep -qE "^commit: [a-f0-9]{40}" "$tmpdir/uspecs/u/uspecs.yml"
}

# Scenario: Install alpha version (remote)
# Downloads from GitHub main branch (requires network access).
# Verifies uspecs.yml written with alpha version, commit field, and AGENTS.md created.
@test "Alpha install (remote, nlia)" {
    local tmpdir
    tmpdir=$(make_temp_repo)
    cd "$tmpdir"
    run bash "$CONF_SH" install -y --alpha --nlia
    [ "$status" -eq 0 ]
    [ -f "$tmpdir/uspecs/u/uspecs.yml" ]
    [ -f "$tmpdir/AGENTS.md" ]
    grep -q "invocation_methods:.*nlia" "$tmpdir/uspecs/u/uspecs.yml"
    grep -qE "^commit: [a-f0-9]{40}" "$tmpdir/uspecs/u/uspecs.yml"
    # Alpha version string contains "-a"
    grep -qE "^version: .*-a" "$tmpdir/uspecs/u/uspecs.yml"
}

# Scenario: Install via curl pipe
# Simulates the README install command by piping conf.sh to bash (no BASH_SOURCE[0]).
# Uses local file piped to bash instead of actual curl to test the fix before it's on main.
# Verifies the two-phase flow: pipe (self-contained) -> downloaded conf.sh apply.
@test "Alpha install (curl pipe)" {
    local tmpdir
    tmpdir=$(make_temp_repo)
    cd "$tmpdir"
    run bash -c "cat '$CONF_SH' | bash -s install -y --alpha --nlia 2>&1"
    [ "$status" -eq 0 ]
    [ -f "$tmpdir/uspecs/u/uspecs.yml" ]
    [ -f "$tmpdir/AGENTS.md" ]
    grep -q "invocation_methods:.*nlia" "$tmpdir/uspecs/u/uspecs.yml"
    grep -qE "^commit: [a-f0-9]{40}" "$tmpdir/uspecs/u/uspecs.yml"
    grep -qE "^version: .*-a" "$tmpdir/uspecs/u/uspecs.yml"
}

# Scenario: Installation failure - uspecs already installed
# Verifies exit non-zero and correct error message
@test "Already installed failure" {
    local tmpdir
    tmpdir=$(make_temp_repo)
    mkdir -p "$tmpdir/uspecs/u"
    touch "$tmpdir/uspecs/u/uspecs.yml"
    cd "$tmpdir"
    run bash -c "bash '$CONF_SH' install --nlia 2>&1"
    [ "$status" -ne 0 ]
    echo "$output" | grep -q "already installed"
}

