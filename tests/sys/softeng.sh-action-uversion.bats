#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

@test "uversion: scn: Display version: source repo emits sentinel" {
    cd "$PROJECT_ROOT"

    uspecs action uversion
    [ "$status" -eq 0 ]
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"Action: uversion"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *'<instruction id="instr_uversion"'* ]]
    [[ "$output" == *"0.0.0-source"* ]]
}

@test "uversion: rejects unknown arguments" {
    cd "$PROJECT_ROOT"

    uspecs action uversion --bogus
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Unknown argument"* ]]
}
