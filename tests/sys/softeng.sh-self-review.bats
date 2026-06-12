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
    # Mirror helpers.bash _setup_project_root path normalization: on
    # MSYS/Cygwin convert to mixed (C:/...) format so PROJECT_ROOT matches
    # the form softeng.sh's _CTX_SCRIPT_DIR emits via `cygpath -m`. Without
    # this the rendered absolute softeng_sh path (mixed) would not match
    # $PROJECT_ROOT (POSIX /c/...).
    local _root="$REPO_ROOT"
    case "$OSTYPE" in
        msys*|cygwin*) _root=$(cygpath -m "$_root") ;;
    esac
    export PROJECT_ROOT="$_root"
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

@test "self-review: construction Stage A chains to Stage B" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type construction --stage A
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_self_review_construction_a"'* ]]
    [[ "$output" == *"--stage B"* ]]
}

@test "self-review: construction Stage B chains to report" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type construction --stage B
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_self_review_construction_b"'* ]]
    [[ "$output" == *[Rr]eport* ]]
    # Must NOT chain to Stage C
    [[ "$output" != *"--stage C"* ]]
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

@test "self-review: --concurrency rejected as unknown argument" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type construction --stage A --concurrency
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Unknown"* ]]
}

@test "self-review: --stage C rejected" {
    cd "$PROJECT_ROOT"

    # Stage C is no longer a valid stage for any --type
    uspecs self-review --type construction --stage C
    [ "$status" -ne 0 ]

    uspecs self-review --type specs --stage C
    [ "$status" -ne 0 ]
}

@test "self-review: specs has only Stage A (Stage B rejected)" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type specs --stage B
    [ "$status" -ne 0 ]
}

@test "self-review: rejects unknown trailing arguments" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type specs --stage A --bogus
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Unknown"* ]]
}

# ---------------------------------------------------------------------------
# scn: Specs retry budget (-b N)
# `self-review --type specs --stage A -b N` controls a retry loop: when N>0 the
# prompt renders a retry instruction with `-b (N-1)`; when N==0 or -b is
# absent, no retry block is emitted. -b is rejected for --type construction
# and for negative values.
# ---------------------------------------------------------------------------

@test "self-review: -b 4 renders budget=4 and next_budget=3" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type specs --stage A -b 4
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_self_review_specs_a"'* ]]
    # Retry block must reference the decremented budget
    [[ "$output" == *"self-review --type specs --stage A -b 3"* ]]
}

@test "self-review: -b 1 renders budget=1 and next_budget=0" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type specs --stage A -b 1
    [ "$status" -eq 0 ]
    [[ "$output" == *"self-review --type specs --stage A -b 0"* ]]
}

@test "self-review: -b 0 accepts but emits no retry block" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type specs --stage A -b 0
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_self_review_specs_a"'* ]]
    # Terminal "report results" remains
    [[ "$output" == *[Rr]eport* ]]
    # No retry re-invocation rendered
    [[ "$output" != *"self-review --type specs --stage A -b"* ]]
}

@test "self-review: no -b emits no retry block" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type specs --stage A
    [ "$status" -eq 0 ]
    [[ "$output" == *[Rr]eport* ]]
    [[ "$output" != *"self-review --type specs --stage A -b"* ]]
}

@test "self-review: -b rejected with --type construction" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type construction --stage A -b 1
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"-b requires --type specs"* ]]
}

@test "self-review: -b rejects negative values" {
    cd "$PROJECT_ROOT"

    uspecs self-review --type specs --stage A -b -1
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"non-negative"* ]]
}

@test "self-review: rendered review-template invocations use absolute softeng_sh path" {
    cd "$PROJECT_ROOT"

    # Specs Stage A with budget: retry line must use the absolute path, not
    # a hardcoded "bin/softeng.sh" relative reference. The path is double-quoted
    # in the rendered command so spaces in install paths (e.g. C:\Program Files)
    # do not split the bash invocation.
    uspecs self-review --type specs --stage A -b 2
    [ "$status" -eq 0 ]
    [[ "$output" == *"\"$PROJECT_ROOT/bin/softeng.sh\" self-review --type specs --stage A -b 1"* ]]
    [[ "$output" != *"bash bin/softeng.sh self-review --type specs"* ]]

    # Construction Stage A: advance to Stage B must use the absolute path
    uspecs self-review --type construction --stage A
    [ "$status" -eq 0 ]
    [[ "$output" == *"\"$PROJECT_ROOT/bin/softeng.sh\" self-review --type construction --stage B"* ]]
    [[ "$output" != *"bash bin/softeng.sh self-review --type construction --stage B"* ]]
}
