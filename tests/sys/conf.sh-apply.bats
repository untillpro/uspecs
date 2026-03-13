#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

_write_uspecs_yml() {
    local project_dir="$1" version="$2"
    cat > "$project_dir/uspecs/u/uspecs.yml" <<EOF
# uspecs installation metadata
# DO NOT EDIT - managed by uspecs
version: $version
invocation_methods: []
installed_at: 2026-01-01T00:00:00Z
modified_at: 2026-01-01T00:00:00Z
EOF
}

@test "apply update --pr switches back to original branch when already up to date" {
    cd "$PROJECT_ROOT"

    # Write metadata with version 1.0.0 and commit to main/origin
    _write_uspecs_yml "$PROJECT_ROOT" "1.0.0"
    git add .
    git commit -q -m "install uspecs 1.0.0"
    git push -q origin main

    # Simulate being on a PR branch before calling apply
    git checkout -b update-uspecs-1.0.0--pr

    # Calling apply update with the same --version and --current-version triggers the
    # "already up to date" path: ffdefault switches to main first, then the version
    # check short-circuits and switches back to prev_branch.
    run bash "$REPO_ROOT/uspecs/u/scripts/conf.sh" apply update \
        --project-dir "$PROJECT_ROOT" \
        --version "1.0.0" \
        --current-version "1.0.0" \
        --pr

    [ "$status" -eq 0 ]
    [[ "$output" == *"Already up to date"* ]]

    local current_branch
    current_branch=$(git -C "$PROJECT_ROOT" symbolic-ref --short HEAD)
    [ "$current_branch" = "update-uspecs-1.0.0--pr" ]
}

