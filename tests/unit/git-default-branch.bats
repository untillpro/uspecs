#!/usr/bin/env bats
set -Eeuo pipefail

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
    source "$REPO_ROOT/uspecs/u/scripts/_lib/git.sh"

    # On Windows (MSYS/Cygwin), bash /tmp and git /tmp map to different Windows
    # directories. Convert to a mixed Windows path so both agree on the same location.
    local _tmpdir="$BATS_TEST_TMPDIR"
    case "$OSTYPE" in
        msys*|cygwin*) _tmpdir=$(cygpath -m "$_tmpdir") ;;
    esac

    export TEST_REPO="$_tmpdir/repo"
    local origin_repo="$_tmpdir/origin.git"

    # Create local repo with "main" as default branch
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git -c init.defaultBranch=main init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    git commit -q --allow-empty -m "initial"

    # Bare repo as origin (default branch = main)
    git -c init.defaultBranch=main init -q --bare "$origin_repo"
    (cd "$origin_repo" && git symbolic-ref HEAD refs/heads/main)
    git remote add origin "$origin_repo"
    git push -q origin HEAD:main
}

@test "git_default_branch_name: only main exists -> returns main" {
    cd "$TEST_REPO"
    # Default setup: only "main" branch exists
    run git_default_branch_name
    [ "$status" -eq 0 ]
    [[ "$output" == "main" ]]
}

@test "git_default_branch_name: only master exists -> returns master" {
    cd "$TEST_REPO"
    # Rename main to master
    git branch -m main master
    run git_default_branch_name
    [ "$status" -eq 0 ]
    [[ "$output" == "master" ]]
}

@test "git_default_branch_name: both main and master exist -> falls back to remote" {
    cd "$TEST_REPO"
    # Create master alongside main
    git branch master
    run git_default_branch_name
    [ "$status" -eq 0 ]
    # Remote default is main
    [[ "$output" == "main" ]]
}

@test "git_default_branch_name: neither main nor master exist -> falls back to remote" {
    cd "$TEST_REPO"
    # Rename main to something else
    git branch -m main develop
    run git_default_branch_name
    [ "$status" -eq 0 ]
    # Remote default is main
    [[ "$output" == "main" ]]
}
