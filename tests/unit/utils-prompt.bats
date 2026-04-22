#!/usr/bin/env bats
set -Eeuo pipefail

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
    source "$REPO_ROOT/bin/_lib/utils.sh"
}

# prompt contract: script exits with error after prompt_start_log - AGENT_INSTRUCTIONS present
@test "prompt contract: script exits with error after prompt_start_log: output contains AGENT_INSTRUCTIONS" {
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        prompt_start_log
        echo 'some log output'
        exit 1
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
}

# prompt contract: results mode - emits results meta-instruction
@test "prompt contract: results mode: emits results meta-instruction" {
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        prompt_start_log
        echo 'some log output'
        prompt_start_instructions 'results'
        echo 'Content here'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"Inform user about the results, see below."* ]]
    [[ "$output" == *"Content here"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
}

# prompt contract: action mode - emits action meta-instruction
@test "prompt contract: action mode: emits action meta-instruction" {
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        prompt_start_log
        echo 'some log output'
        prompt_start_instructions 'action'
        echo 'Artifact definition here'
        echo 'Instructions here'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"See artifact definitions below, followed by instructions."* ]]
    [[ "$output" != *"Inform user about the results"* ]]
    [[ "$output" == *"Artifact definition here"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
}

# prompt contract: no parameter - error
@test "prompt contract: no parameter: exits with error" {
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        prompt_start_log
        echo 'some log output'
        prompt_start_instructions
    "
    [ "$status" -ne 0 ]
}

# prompt contract: unknown mode - error
@test "prompt contract: unknown mode: exits with error" {
    run bash -c "
        source '$REPO_ROOT/bin/_lib/utils.sh'
        prompt_start_log
        echo 'some log output'
        prompt_start_instructions 'unknown'
    "
    [ "$status" -ne 0 ]
}

