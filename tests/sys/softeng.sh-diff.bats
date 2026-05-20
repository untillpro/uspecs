#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# Every test in this file needs a git repo with an `origin` remote because
# `uspecs diff` resolves against `origin/<default-branch>`, so override setup()
# at file scope with the cheap default plus _setup_git_origin.
setup() {
    _setup_project_root
    _setup_gh_stub
    _setup_git_origin
}

@test "diff specs outputs diff between HEAD and default branch" {
    cd "$PROJECT_ROOT"

    git checkout -b diff-branch
    echo "# New spec" > "$PROJECT_ROOT/uspecs/specs/new-spec.md"
    git add .
    git commit -q -m "add spec"

    uspecs diff specs
    [ "$status" -eq 0 ]
    [[ "$output" == *"new-spec.md"* ]]
}


@test "diff file outputs per-file diff against merge-base" {
    cd "$PROJECT_ROOT"

    git checkout -b diff-file-branch
    echo "file content" > "$PROJECT_ROOT/my-source.txt"
    echo "other content" > "$PROJECT_ROOT/other-file.txt"
    git add .
    git commit -q -m "add two files"

    uspecs diff file my-source.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"my-source.txt"* ]]
    [[ "$output" == *"file content"* ]]
    # Should not contain the other file
    [[ "$output" != *"other-file.txt"* ]]
}

