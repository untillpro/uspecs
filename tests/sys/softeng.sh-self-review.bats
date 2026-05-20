#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# self-review is a read-only command that emits a prompt and exits. It does
# not need git or an origin remote, but it does need $PROJECT_ROOT/bin/softeng.sh
# to exist. The default setup() in helpers.bash builds an isolated mirror of
# bin/ in a temp dir via _setup_project_root, which is unnecessary here -- we
# can point PROJECT_ROOT at the real repo instead. Override setup() to do
# only that.
setup() {
    export PROJECT_ROOT="$REPO_ROOT"
}

# ---------------------------------------------------------------------------
# scn: Stage prompt dispatch -- correct instruction id per (type, stage)
# ---------------------------------------------------------------------------

@test "self-review: specs Stage A emits the specs Stage A instruction" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type specs --stage A
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_self_review_specs_a"'* ]]
    # Terminal stage: instructs Agent to report results
    [[ "$output" == *[Rr]eport* ]]
}

@test "self-review: construction Stage A chains to Stage B (propagating --concurrency when set)" {
    cd "$PROJECT_ROOT"

    # Without --concurrency
    uspecs self-review --type construction --stage A
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_self_review_construction_a"'* ]]
    [[ "$output" == *"--stage B"* ]]

    # With --concurrency: same prompt, --concurrency must be propagated
    uspecs self-review --type construction --stage A --concurrency
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_self_review_construction_a"'* ]]
    [[ "$output" == *"--stage B"* ]]
    [[ "$output" == *"--concurrency"* ]]
}

@test "self-review: construction Stage B without --concurrency chains to report" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type construction --stage B
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_self_review_construction_b"'* ]]
    [[ "$output" == *[Rr]eport* ]]
    # Must NOT chain to Stage C
    [[ "$output" != *"--stage C"* ]]
}

@test "self-review: construction Stage B with --concurrency chains to Stage C --concurrency" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type construction --stage B --concurrency
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_self_review_construction_b"'* ]]
    [[ "$output" == *"--stage C"* ]]
    [[ "$output" == *"--concurrency"* ]]
}

@test "self-review: construction Stage C emits Stage C prompt and reports results" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type construction --stage C --concurrency
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_self_review_construction_c"'* ]]
    [[ "$output" == *[Rr]eport* ]]
}

# ---------------------------------------------------------------------------
# scn: Validation -- bad/missing arguments
# ---------------------------------------------------------------------------

@test "self-review: rejects unknown --type" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type bogus --stage A
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"--type"* ]]
}

@test "self-review: rejects unknown --stage" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type specs --stage Z
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"--stage"* ]]
}

@test "self-review: rejects missing --type" {
    cd "$PROJECT_ROOT"

    uspecs self-review --stage A
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"--type"* ]]
}

@test "self-review: rejects missing --stage" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type specs
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"--stage"* ]]
}

@test "self-review: --concurrency rejected with --type specs" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type specs --stage A --concurrency
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"--concurrency"* ]]
}

@test "self-review: specs has only Stage A (Stage B/C rejected)" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type specs --stage B
    [ "$status" -ne 0 ]

    uspecs self-review --type specs --stage C
    [ "$status" -ne 0 ]
}

@test "self-review: rejects unknown trailing arguments" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type specs --stage A --bogus
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Unknown"* ]]
}
