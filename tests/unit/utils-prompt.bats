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

# prompt contract: script exits successfully - script error instructions not emitted
@test "prompt contract: script exits successfully: script error instructions not emitted" {
    run bash -c "
        source '$REPO_ROOT/uspecs/u/scripts/_lib/utils.sh'
        prompt_start_log
        echo 'some log output'
        prompt_finish_log_start_instructions
        echo 'normal instructions'
        prompt_finish_instructions
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" != *"The script exited with an error."* ]]
}

