#!/usr/bin/env bats
set -Eeuo pipefail

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
    source "$REPO_ROOT/bin/_lib/utils.sh"
}

# atexit_add - single handler runs on exit
@test "atexit_add: single handler runs on exit" {
    local marker="$BATS_TEST_TMPDIR/marker"
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        atexit_add 'touch $marker'
    "
    [ "$status" -eq 0 ]
    [ -f "$marker" ]
}

# atexit_add multiple - all handlers run in registration order
@test "atexit_add: multiple handlers run in registration order" {
    local log="$BATS_TEST_TMPDIR/log"
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        atexit_add 'echo first >> $log'
        atexit_add 'echo second >> $log'
        atexit_add 'echo third >> $log'
    "
    [ "$status" -eq 0 ]
    [ "$(cat "$log")" = "$(printf 'first\nsecond\nthird')" ]
}

# atexit_push / atexit_pop - pushed cmd runs on exit; popped cmd does not
@test "atexit_push/atexit_pop: pushed cmd runs; popped cmd does not" {
    local pushed="$BATS_TEST_TMPDIR/pushed"
    local popped="$BATS_TEST_TMPDIR/popped"
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        atexit_push 'touch $pushed'
        atexit_push 'touch $popped'
        atexit_pop
    "
    [ "$status" -eq 0 ]
    [ -f "$pushed" ]
    [ ! -f "$popped" ]
}

# atexit_push LIFO order - last pushed runs first
@test "atexit_push: executes in LIFO order" {
    local log="$BATS_TEST_TMPDIR/log"
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        atexit_push 'echo first >> $log'
        atexit_push 'echo second >> $log'
        atexit_push 'echo third >> $log'
    "
    [ "$status" -eq 0 ]
    [ "$(cat "$log")" = "$(printf 'third\nsecond\nfirst')" ]
}

# atexit_pop on empty stack - no error
@test "atexit_pop: no error on empty stack" {
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        atexit_pop
    "
    [ "$status" -eq 0 ]
}

# sourcing utils.sh twice is harmless (source guard)
@test "atexit: double source does not cause recursion" {
    local marker="$BATS_TEST_TMPDIR/marker"
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        source '$REPO_ROOT/bin/_lib/utils.sh'
        atexit_add 'touch $marker'
    "
    [ "$status" -eq 0 ]
    [ -f "$marker" ]
}

# chaining - EXIT trap registered before sourcing utils.sh is still called
@test "atexit: chains previously registered EXIT trap" {
    local marker="$BATS_TEST_TMPDIR/prev"
    run bash -c "
        trap 'touch $marker' EXIT
        source '$REPO_ROOT/bin/_lib/utils.sh'
        atexit_add 'true'
    "
    [ "$status" -eq 0 ]
    [ -f "$marker" ]
}

# chaining - atexit handlers run even when chained trap calls exit
@test "atexit: handlers run before chained trap that calls exit" {
    local cleanup="$BATS_TEST_TMPDIR/cleanup"
    local chained="$BATS_TEST_TMPDIR/chained"
    run bash -c "
        trap 'touch $chained; exit 0' EXIT
        source '$REPO_ROOT/bin/_lib/utils.sh'
        atexit_add 'touch $cleanup'
    "
    [ "$status" -eq 0 ]
    [ -f "$cleanup" ]
    [ -f "$chained" ]
}

# atexit_add rejects multiple arguments
@test "atexit_add: rejects multiple arguments" {
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        atexit_add rm -f /tmp/foo
    "
    [ "$status" -ne 0 ]
    [[ "$output" == *"atexit_add: expected 1 argument"* ]]
}

# atexit_push rejects multiple arguments
@test "atexit_push: rejects multiple arguments" {
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        atexit_push rm -f /tmp/foo
    "
    [ "$status" -ne 0 ]
    [[ "$output" == *"atexit_push: expected 1 argument"* ]]
}

# exit code preserved - original non-zero rc propagates through dispatcher
@test "atexit: original non-zero exit code is preserved" {
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        atexit_add 'true'
        exit 42
    "
    [ "$status" -eq 42 ]
}


# temp_create_file creates a file and cleans it up on exit
@test "temp_create_file: creates file and cleans up on exit" {
    local path_file="$BATS_TEST_TMPDIR/tmp_path"
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        temp_create_file my_tmp
        echo \"\$my_tmp\" > '$path_file'
        [ -f \"\$my_tmp\" ] || exit 10
    "
    [ "$status" -eq 0 ]
    local tmp_path
    tmp_path=$(cat "$path_file")
    [ ! -f "$tmp_path" ]
}

# temp_create_dir creates a directory and cleans it up on exit
@test "temp_create_dir: creates dir and cleans up on exit" {
    local path_file="$BATS_TEST_TMPDIR/tmp_path"
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        temp_create_dir my_tmp
        echo \"\$my_tmp\" > '$path_file'
        [ -d \"\$my_tmp\" ] || exit 10
    "
    [ "$status" -eq 0 ]
    local tmp_path
    tmp_path=$(cat "$path_file")
    [ ! -d "$tmp_path" ]
}
