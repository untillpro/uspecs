#!/usr/bin/env bats
set -Eeuo pipefail

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
    source "$REPO_ROOT/bin/_lib/utils.sh"
}

@test "quiet: suppresses stdout on success" {
    run quiet echo "hello world"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "quiet: suppresses stderr on success" {
    run quiet bash -c 'echo "noise" >&2'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "quiet: suppresses both stdout and stderr on success" {
    run quiet bash -c 'echo "out"; echo "err" >&2'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "quiet: returns zero on success" {
    run quiet true
    [ "$status" -eq 0 ]
}

@test "quiet: returns original exit code on failure" {
    run quiet bash -c 'exit 42'
    [ "$status" -eq 42 ]
}

@test "quiet: dumps stdout on failure" {
    run quiet bash -c 'echo "out-msg"; exit 1'
    [ "$status" -eq 1 ]
    [[ "$output" == *"out-msg"* ]]
}

@test "quiet: dumps stderr on failure" {
    # bats merges stderr into output
    run quiet bash -c 'echo "err-msg" >&2; exit 1'
    [ "$status" -eq 1 ]
    [[ "$output" == *"err-msg"* ]]
}

@test "quiet: dumps both stdout and stderr on failure" {
    run quiet bash -c 'echo "out-line"; echo "err-line" >&2; exit 3'
    [ "$status" -eq 3 ]
    [[ "$output" == *"out-line"* ]]
    [[ "$output" == *"err-line"* ]]
}

@test "quiet: no output dumped when command fails silently" {
    run quiet bash -c 'exit 1'
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "quiet: preserves multi-line stdout on failure" {
    run quiet bash -c 'echo "line1"; echo "line2"; echo "line3"; exit 1'
    [ "$status" -eq 1 ]
    [[ "$output" == *"line1"* ]]
    [[ "$output" == *"line2"* ]]
    [[ "$output" == *"line3"* ]]
}


@test "quiet: passes arguments correctly" {
    # Use a command that depends on getting correct arguments
    # shellcheck disable=SC2016
    run quiet bash -c 'test "$1" = "hello" && test "$2" = "world"' _ hello world
    [ "$status" -eq 0 ]
}

