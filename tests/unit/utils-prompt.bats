#!/usr/bin/env bats
set -Eeuo pipefail

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
    source "$REPO_ROOT/uspecs/u/scripts/_lib/utils.sh"
}

# prompt contract: script exits with error after prompt_start_log - AGENT_INSTRUCTIONS present
@test "prompt contract: script exits with error after prompt_start_log: output contains AGENT_INSTRUCTIONS" {
    run bash -c "
        source '$REPO_ROOT/uspecs/u/scripts/_lib/utils.sh'
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

# prompt contract: no parameter - default meta-instruction, auto-close
@test "prompt contract: no parameter: emits default meta-instruction" {
    run bash -c "
        source '$REPO_ROOT/uspecs/u/scripts/_lib/utils.sh'
        prompt_start_log
        echo 'some log output'
        prompt_start_instructions
        echo 'Content here'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"Inform user about the results, see below."* ]]
    [[ "$output" == *"Content here"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
}

# prompt contract: custom meta-instruction replaces default
@test "prompt contract: custom meta-instruction: replaces default" {
    run bash -c "
        source '$REPO_ROOT/uspecs/u/scripts/_lib/utils.sh'
        prompt_start_log
        echo 'some log output'
        prompt_start_instructions 'Ask user to choose an option.'
        echo 'Option 1: foo'
        echo 'Option 2: bar'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"Ask user to choose an option."* ]]
    [[ "$output" != *"Inform user about the results"* ]]
    [[ "$output" == *"Option 1: foo"* ]]
    [[ "$output" == *"</AGENT_INSTRUCTIONS>"* ]]
}

