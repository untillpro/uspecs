#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

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

