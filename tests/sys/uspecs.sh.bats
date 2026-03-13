#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

@test "unknown command fails with usage error" {
    cd "$PROJECT_ROOT"
    uspecs foobar
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Unknown"* ]]
}
