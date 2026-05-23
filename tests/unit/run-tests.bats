#!/usr/bin/env bats
set -Eeuo pipefail

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

@test "run-tests: unit tests for discover_bats_files" {
    local root="$REPO_ROOT"
    case "$OSTYPE" in
        msys*|cygwin*) root=$(cygpath -m "$root") ;;
    esac
    run python3 "$root/tests/unit/test_run_tests.py"
    echo "$output"
    [ "$status" -eq 0 ]
}
