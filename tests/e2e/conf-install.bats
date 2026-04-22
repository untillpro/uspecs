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
    git -c init.defaultBranch=main -C "$tmpdir" init -q
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
    git -c init.defaultBranch=main init -q --bare "$origin_dir"
    git -C "$tmpdir" remote add origin "$origin_dir"
    git -C "$tmpdir" push -q origin HEAD:main
    git -C "$origin_dir" symbolic-ref HEAD refs/heads/main
    echo "$tmpdir"
}

@test "install: scn: Install stable version: local nlia" {
# And <file> is created if it does not exist
# And instructions are injected into <file>
# And Claude Code skills are copied to .claude/skills/
# method: nlia
# file: AGENTS.md
    local tmpdir
    tmpdir=$(make_temp_repo)
    cd "$tmpdir"
    run bash "$CONF_SH" install -y --local --nlia
    [ "$status" -eq 0 ]
    [ -f "$tmpdir/uspecs/u/uspecs.yml" ]
    [ -f "$tmpdir/AGENTS.md" ]
    grep -q "invocation_methods:.*nlia" "$tmpdir/uspecs/u/uspecs.yml"
    grep -qE "^commit: [a-f0-9]{40}" "$tmpdir/uspecs/u/uspecs.yml"
    # Claude Code skills copied
    [ -f "$tmpdir/.claude/skills/uspecs-fd/SKILL.md" ]
    [ -f "$tmpdir/.claude/skills/uspecs-fd/echo.feature" ]
    [ -f "$tmpdir/.claude/skills/uspecs-fd/echo--reqs.md" ]
}

@test "install: scn: Installation failure: dirty working directory with --pr" {
# Given <condition>
# Then installation fails with "<message>"
# condition: working directory is not clean (--pr)
# message: Working directory has uncommitted changes
    local tmpdir
    tmpdir=$(make_temp_repo_with_origin)
    # Make the working directory dirty
    echo "dirty" > "$tmpdir/dirty.txt"
    # Expose the gh stub so check_prerequisites passes the gh check
    # shellcheck disable=SC2030
    PATH="$BATS_TEST_DIRNAME/../stubs:$PATH"
    cd "$tmpdir"
    run bash -c "bash '$CONF_SH' install -y --local --nlia --pr 2>&1"
    [ "$status" -ne 0 ]
    echo "$output" | grep -q "uncommitted changes"
}

@test "install: scn: Install stable version: local nlic" {
# And <file> is created if it does not exist
# And instructions are injected into <file>
# method: nlic
# file: CLAUDE.md
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

@test "install: scn: Install stable version: local nlia + nlic" {
# And <file> is created if it does not exist
# And instructions are injected into <file>
# file: AGENTS.md, CLAUDE.md
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

@test "install: scn: Install alpha version: remote nlia" {
# Then uspecs is installed from the latest commit on main branch
# And uspecs metadata file is created and describes the alpha version
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

@test "install: scn: Install via curl pipe: alpha nlia" {
# Then conf.sh executes without sourcing any local files (_lib/*, utils.sh)
# And conf.sh downloads the archive and delegates to the downloaded conf.sh apply
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

@test "install: scn: Installation failure: already installed without override" {
# Given <condition>
# Then installation fails with "<message>"
# condition: uspecs is already installed (without --override)
# message: uspecs is already installed, use update instead
    local tmpdir
    tmpdir=$(make_temp_repo)
    mkdir -p "$tmpdir/uspecs/u"
    touch "$tmpdir/uspecs/u/uspecs.yml"
    cd "$tmpdir"
    run bash -c "bash '$CONF_SH' install --nlia 2>&1"
    [ "$status" -ne 0 ]
    echo "$output" | grep -q "already installed"
}

@test "install: scn: Install with --override: different version replaces" {
# And existing installation is replaced regardless of version
    local tmpdir
    tmpdir=$(make_temp_repo)
    cd "$tmpdir"
    # First install
    run bash "$CONF_SH" install -y --local --nlia
    [ "$status" -eq 0 ]
    [ -f "$tmpdir/uspecs/u/uspecs.yml" ]
    # Fake a different installed version so override proceeds with replacement
    sed -i 's/^version: .*/version: 0.0.0/' "$tmpdir/uspecs/u/uspecs.yml"
    sed -i 's/^commit: .*/commit: 0000000000000000000000000000000000000000/' "$tmpdir/uspecs/u/uspecs.yml"
    # Plant a stale file that should be removed by the override install
    touch "$tmpdir/uspecs/u/stale-file.txt"
    # Override install
    run bash "$CONF_SH" install -y --local --nlia --override
    [ "$status" -eq 0 ]
    [ -f "$tmpdir/uspecs/u/uspecs.yml" ]
    grep -q "invocation_methods:.*nlia" "$tmpdir/uspecs/u/uspecs.yml"
    # Stale file must be gone
    [ ! -f "$tmpdir/uspecs/u/stale-file.txt" ]
}

@test "install: scn: Install with --override: version matches" {
# But if installed version equals incoming version, script exits with message suggesting to remove uspecs.yml
    local tmpdir
    tmpdir=$(make_temp_repo)
    cd "$tmpdir"
    # First install
    run bash "$CONF_SH" install -y --local --nlia
    [ "$status" -eq 0 ]
    [ -f "$tmpdir/uspecs/u/uspecs.yml" ]
    # Override install with same version
    run bash "$CONF_SH" install -y --local --nlia --override
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "Remove uspecs.yml to force reinstall"
}

@test "install: scn: Install with --override: version matches with --pr restores branch" {
# But if installed version equals incoming version, script exits with message suggesting to remove uspecs.yml
    local tmpdir
    tmpdir=$(make_temp_repo_with_origin)
    cd "$tmpdir"
    # First install and commit so working tree is clean for --pr
    run bash "$CONF_SH" install -y --local --nlia
    [ "$status" -eq 0 ]
    git -C "$tmpdir" add -A && git -C "$tmpdir" commit -q -m "install uspecs"
    git -C "$tmpdir" push -q origin HEAD:main
    local branch_before
    branch_before=$(git -C "$tmpdir" symbolic-ref --short HEAD)
    # Expose the gh stub so check_prerequisites passes
    # shellcheck disable=SC2030,SC2031
    PATH="$BATS_TEST_DIRNAME/../stubs:$PATH"
    # Override install with same version + --pr
    run bash "$CONF_SH" install -y --local --nlia --override --pr
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "Remove uspecs.yml to force reinstall"
    # Branch must be restored to where it was before
    local branch_after
    branch_after=$(git -C "$tmpdir" symbolic-ref --short HEAD)
    [ "$branch_before" = "$branch_after" ]
}

@test "install: scn: Install with --override: error after branch switch restores branch" {
# Then installation fails and branch is restored via atexit
    local tmpdir
    tmpdir=$(make_temp_repo_with_origin)
    cd "$tmpdir"
    # Install uspecs, commit, push so working tree is clean for --pr
    run bash "$CONF_SH" install -y --local --nlia
    [ "$status" -eq 0 ]
    git -C "$tmpdir" add -A && git -C "$tmpdir" commit -q -m "install uspecs"
    git -C "$tmpdir" push -q origin HEAD:main
    local branch_before
    branch_before=$(git -C "$tmpdir" symbolic-ref --short HEAD)
    # Expose the gh stub so check_prerequisites passes
    # shellcheck disable=SC2031
    PATH="$BATS_TEST_DIRNAME/../stubs:$PATH"
    # Use "apply update" with wrong --current-version to trigger error after atexit_push
    run bash "$CONF_SH" apply update --project-dir "$tmpdir" --version 99.0.0 --current-version WRONG --pr -y
    [ "$status" -ne 0 ]
    echo "$output" | grep -q "does not match expected"
    # Branch must be restored via atexit handler
    local branch_after
    branch_after=$(git -C "$tmpdir" symbolic-ref --short HEAD)
    [ "$branch_before" = "$branch_after" ]
}


