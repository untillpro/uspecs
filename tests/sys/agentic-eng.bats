#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2154
set -Eeuo pipefail

load 'helpers'



# System test for scripts/agentic-eng.sh with the uspecs actions mocked.
#
# The selected agentic tool (auggie/claude) is replaced by a PATH-shim mock
# whose scripted responses deterministically drive the Change Folder, so
# uchange, the per-iteration agent invocation, and upr run without a real
# agent and without creating a real pull request.

AGENTIC_INPUT="implement agentic engineering from AIR-4444"

# _setup_agent_stub [--git]: put the mock agent tools (auggie/claude) on PATH
# and reset the AGENT_MOCK_* state. With --git, also set up a git repository.
# The stubs live in tests/sys/stubs (already on PATH via the default gh-stub
# setup); their behaviour is controlled through AGENT_MOCK_* variables the test
# exports before invoking the script.
_setup_agent_stub() {
    if [ "${1:-}" = "--git" ]; then
        _setup_git_repo
    elif [ $# -gt 0 ]; then
        echo "unknown _setup_agent_stub option: $1" >&2
        return 2
    fi

    chmod +x "$STUBS_DIR/agent-stub" "$STUBS_DIR/auggie" "$STUBS_DIR/claude"
    case ":$PATH:" in
        *":$STUBS_DIR:"*) ;;
        *) export PATH="$STUBS_DIR:$PATH" ;;
    esac

    mkdir -p "$PROJECT_ROOT/.mock"
    export AGENT_MOCK_LOG="$PROJECT_ROOT/.mock/agent.log"
    export AGENT_MOCK_UPR_LOG="$PROJECT_ROOT/.mock/upr.log"
    export AGENT_MOCK_COUNT="$PROJECT_ROOT/.mock/count"
    export AGENT_MOCK_CF="uspecs/changes/2699010101-mock"
    export AGENT_MOCK_BRANCH="AIR-mock-agentic"
    : > "$AGENT_MOCK_LOG"
    rm -f "$AGENT_MOCK_UPR_LOG" "$AGENT_MOCK_COUNT"
}

run_agentic() {
    run --separate-stderr bash "$REPO_ROOT/scripts/agentic-eng.sh" "$@"
}

_assert_namespace_for_stream() {
    local stream="$1" namespace="$2" log
    _setup_agent_stub --git
    export AGENT_MOCK_ADVANCE=complete
    run_agentic --pr --stream "$stream" --agent-tool auggie "$AGENTIC_INPUT"
    log="$(cat "$AGENT_MOCK_LOG")"
    [[ "$log" == *"$namespace:uchange $AGENTIC_INPUT"* ]]
    [[ "$log" == *"$namespace:uimpl"* ]]
    [[ "$log" == *"$namespace:upr"* ]]
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Rule: Outcomes
# ---------------------------------------------------------------------------

@test "agentic-eng: scn: Loop reaches a completed Construction section: auggie with --pr" {
    # Given Engineer runs the agentic engineering script with --pr, input, "--stream dev", and "--agent-tool auggie"
    _setup_agent_stub --git
    # And the change request and its branch are created
    # When an iteration leaves the Change Folder with a Construction section whose checklist items are all checked "[x]"
    export AGENT_MOCK_ADVANCE=complete
    run_agentic --pr --stream dev --agent-tool auggie "$AGENTIC_INPUT"
    # Then the loop stops
    # And a pull request is created for the change
    [ -f "$AGENT_MOCK_UPR_LOG" ]
    [[ "$output" == *"opened pull request"* ]]
    # And the script exits with status 0
    [ "$status" -eq 0 ]
}

@test "agentic-eng: scn: Loop reaches a completed Construction section without --pr" {
    # Given Engineer runs the agentic engineering script without "--pr"
    _setup_agent_stub --git
    export AGENT_MOCK_ADVANCE=complete
    # When an iteration leaves the Change Folder completed
    run_agentic --stream dev --agent-tool auggie "$AGENTIC_INPUT"
    # Then the loop stops successfully
    [ "$status" -eq 0 ]
    [[ "$output" == *"pull request not opened"* ]]
    # And no pull request is created
    [ ! -f "$AGENT_MOCK_UPR_LOG" ]
}

@test "agentic-eng: scn: Loop ends without a completed Construction section: unchanged Change Folder" {
    # | stop_condition                                                |
    # | an iteration leaves the Change Folder unchanged               |
    # Given Engineer runs the agentic engineering script with input, "--stream dev", and "--agent-tool claude"
    _setup_agent_stub --git
    # When <stop_condition>
    # stop_condition = an iteration leaves the Change Folder unchanged
    export AGENT_MOCK_ADVANCE=noop
    run_agentic --stream dev --agent-tool claude "$AGENTIC_INPUT"
    # Then the loop stops
    [[ "$stderr" == *"nochange"* ]]
    # And a noop first pass stops immediately without a second agent invocation
    [ "$(grep -c 'uspecs-dev:uimpl' "$AGENT_MOCK_LOG")" -eq 1 ]
    # And no pull request is created
    [ ! -f "$AGENT_MOCK_UPR_LOG" ]
    # And the script exits with a non-zero status and a diagnostic message
    [ "$status" -ne 0 ]
    [[ "$stderr" == *"without a completed Construction section"* ]]
}

@test "agentic-eng: scn: Loop ends without a completed Construction section: iteration cap" {
    # | stop_condition                                                |
    # | the loop reaches 40 minutes or 40 iterations, whichever first |
    # Given Engineer runs the agentic engineering script with input, "--stream dev", and "--agent-tool claude"
    _setup_agent_stub --git
    # When <stop_condition>
    # stop_condition = the loop reaches 40 minutes or 40 iterations, whichever first
    export AGENT_MOCK_ADVANCE=grow AGENTIC_ENG_MAX_ITERS=3
    run_agentic --stream dev --agent-tool claude "$AGENTIC_INPUT"
    # Then the loop stops
    [[ "$stderr" == *"itercap"* ]]
    # And each loop pass advances the Change Folder with the selected agentic tool
    [ "$(grep -c 'uspecs-dev:uimpl' "$AGENT_MOCK_LOG")" -eq 3 ]
    # And no pull request is created
    [ ! -f "$AGENT_MOCK_UPR_LOG" ]
    # And the script exits with a non-zero status and a diagnostic message
    [ "$status" -ne 0 ]
}

@test "agentic-eng: scn: Loop ends without a completed Construction section: time cap" {
    # | stop_condition                                                |
    # | the loop reaches 40 minutes or 40 iterations, whichever first |
    # Given Engineer runs the agentic engineering script with input, "--stream dev", and "--agent-tool claude"
    _setup_agent_stub --git
    # When <stop_condition>
    # stop_condition = the loop reaches 40 minutes or 40 iterations, whichever first
    export AGENT_MOCK_ADVANCE=grow AGENTIC_ENG_MAX_SECONDS=0
    run_agentic --stream dev --agent-tool claude "$AGENTIC_INPUT"
    # Then the loop stops
    [[ "$stderr" == *"timecap"* ]]
    # And no pull request is created
    [ ! -f "$AGENT_MOCK_UPR_LOG" ]
    # And the script exits with a non-zero status and a diagnostic message
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Rule: Verbose mode
# ---------------------------------------------------------------------------

@test "agentic-eng: scn: Verbose flag reports execution trace" {
    # Given Engineer runs the agentic engineering script with "-v"
    _setup_agent_stub --git
    export AGENT_MOCK_ADVANCE=complete
    # When the script delegates commands and evaluates loop state
    run_agentic -v --pr --stream dev --agent-tool auggie "$AGENTIC_INPUT"
    # Then stderr includes issued commands, status, decisions, and summaries
    [[ "$stderr" == *"[agentic-eng] [status] starting"* ]]
    [[ "$stderr" == *'[agentic-eng] [command] auggie -p -q "/uspecs-dev:uchange'* ]]
    [[ "$stderr" == *"[agentic-eng] [status] iteration 1/"* ]]
    [[ "$stderr" == *"[agentic-eng] [decision] open PR: --pr specified"* ]]
    [[ "$stderr" == *"[agentic-eng] [summary] pull-request: opened"* ]]
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Rule: Delegated steps
# ---------------------------------------------------------------------------

@test "agentic-eng: scn: Change creation delegates to uchange" {
    _setup_agent_stub --git
    export AGENT_MOCK_ADVANCE=complete
    # When the agentic engineering script creates the change request from input
    run_agentic --pr --stream dev --agent-tool auggie "$AGENTIC_INPUT"
    # Then it follows the "Create change request" feature in uchange.feature for input handling, branch creation, and Change Folder creation
    [[ "$(cat "$AGENT_MOCK_LOG")" == *"/uspecs-dev:uchange $AGENTIC_INPUT"* ]]
    [ -d "$PROJECT_ROOT/$AGENT_MOCK_CF" ]
    [ "$(git -C "$PROJECT_ROOT" branch --show-current)" = "$AGENT_MOCK_BRANCH" ]
    [ "$status" -eq 0 ]
}

@test "agentic-eng: scn: Input can be read from stdin" {
    _setup_agent_stub --git
    export AGENT_MOCK_ADVANCE=complete
    # When the agentic engineering script reads input from stdin
    run --separate-stderr bash "$REPO_ROOT/scripts/agentic-eng.sh" \
        --pr --stdin --stream dev --agent-tool auggie <<< "$AGENTIC_INPUT"
    # Then the stdin input is passed to uchange
    [[ "$(cat "$AGENT_MOCK_LOG")" == *"/uspecs-dev:uchange $AGENTIC_INPUT"* ]]
    [ "$status" -eq 0 ]
}

@test "agentic-eng: scn: Pull request creation delegates to upr" {
    _setup_agent_stub --git
    export AGENT_MOCK_ADVANCE=complete
    # When the agentic engineering script opens the pull request
    run_agentic --pr --stream dev --agent-tool auggie "$AGENTIC_INPUT"
    # Then it follows the "Create pull request from current branch" feature in upr.feature
    [[ "$(cat "$AGENT_MOCK_LOG")" == *"/uspecs-dev:upr"* ]]
    [ -f "$AGENT_MOCK_UPR_LOG" ]
    [ "$status" -eq 0 ]
}

@test "agentic-eng: scn: Stream selects the uspecs command namespace: dev" {
    _assert_namespace_for_stream dev /uspecs-dev
}

@test "agentic-eng: scn: Stream selects the uspecs command namespace: rc" {
    _assert_namespace_for_stream rc /uspecs-rc
}

@test "agentic-eng: scn: Stream selects the uspecs command namespace: release" {
    _assert_namespace_for_stream release /uspecs
}

# ---------------------------------------------------------------------------
# Rule: Fail fast
# ---------------------------------------------------------------------------

@test "agentic-eng: scn: Change creation did not produce its preconditions: the working branch" {
    # | missing            |
    # | the working branch |
    # Given Engineer runs the agentic engineering script with input, "--stream dev", and "--agent-tool auggie"
    _setup_agent_stub --git
    # When change request creation completes and <missing> is not created
    # missing = the working branch
    export AGENT_MOCK_NO_BRANCH=1
    run_agentic --stream dev --agent-tool auggie "$AGENTIC_INPUT"
    # Then the loop does not start
    [ ! -f "$AGENT_MOCK_COUNT" ]
    # And no pull request is created
    [ ! -f "$AGENT_MOCK_UPR_LOG" ]
    # And the script exits with a non-zero status and a diagnostic message
    [ "$status" -ne 0 ]
    [[ "$stderr" == *"did not create a working branch"* ]]
}

@test "agentic-eng: scn: Change creation did not produce its preconditions: the Change Folder" {
    # | missing           |
    # | the Change Folder |
    # Given Engineer runs the agentic engineering script with input, "--stream dev", and "--agent-tool auggie"
    _setup_agent_stub --git
    # When change request creation completes and <missing> is not created
    # missing = the Change Folder
    export AGENT_MOCK_NO_CF=1
    run_agentic --stream dev --agent-tool auggie "$AGENTIC_INPUT"
    # Then the loop does not start
    [ ! -f "$AGENT_MOCK_COUNT" ]
    # And no pull request is created
    [ ! -f "$AGENT_MOCK_UPR_LOG" ]
    # And the script exits with a non-zero status and a diagnostic message
    [ "$status" -ne 0 ]
    [[ "$stderr" == *"did not create a Change Folder"* ]]
}

# ---------------------------------------------------------------------------
# Rule: Argument validation
# ---------------------------------------------------------------------------

@test "agentic-eng: scn: Required and valid arguments: without input" {
    # | invocation                             | requirement                               |
    # | without input                          | input is required                         |
    # When Engineer runs the agentic engineering script <invocation>
    run --separate-stderr bash "$REPO_ROOT/scripts/agentic-eng.sh"
    # Then error indicates <requirement>
    # requirement = input is required
    [ "$status" -eq 2 ]
    [[ "$stderr" == *"input is required"* ]]
    # And no change request is created
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2699010101-mock" ]
}

@test "agentic-eng: scn: Required and valid arguments: with input but no --stream parameter" {
    # | invocation                             | requirement                               |
    # | with input but no --stream parameter     | --stream is required                    |
    # When Engineer runs the agentic engineering script <invocation>
    run --separate-stderr bash "$REPO_ROOT/scripts/agentic-eng.sh" "$AGENTIC_INPUT"
    # Then error indicates <requirement>
    # requirement = --stream is required
    [ "$status" -eq 2 ]
    [[ "$stderr" == *"--stream is required"* ]]
    # And no change request is created
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2699010101-mock" ]
}

@test "agentic-eng: scn: Required and valid arguments: with --stdin and positional input" {
    # When Engineer provides both --stdin and positional input
    run --separate-stderr bash "$REPO_ROOT/scripts/agentic-eng.sh" \
        --stdin --stream dev --agent-tool auggie "$AGENTIC_INPUT" <<< "$AGENTIC_INPUT"
    # Then error indicates the input sources are mutually exclusive
    [ "$status" -eq 2 ]
    [[ "$stderr" == *"--stdin cannot be used with positional input"* ]]
    # And no change request is created
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2699010101-mock" ]
}

@test "agentic-eng: scn: Required and valid arguments: with --stdin and empty input" {
    # When Engineer provides --stdin but stdin is empty
    run --separate-stderr bash "$REPO_ROOT/scripts/agentic-eng.sh" \
        --stdin --stream dev --agent-tool auggie <<< ""
    # Then error indicates stdin input is empty
    [ "$status" -eq 2 ]
    [[ "$stderr" == *"stdin input is empty"* ]]
    # And no change request is created
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2699010101-mock" ]
}

@test "agentic-eng: scn: Required and valid arguments: with --stream prod" {
    # | invocation          | requirement                            |
    # | with --stream "prod" | the stream must be dev, rc, or release |
    # When Engineer runs the agentic engineering script <invocation>
    run --separate-stderr bash "$REPO_ROOT/scripts/agentic-eng.sh" --stream prod --agent-tool auggie "$AGENTIC_INPUT"
    # Then error indicates <requirement>
    # requirement = the stream must be dev, rc, or release
    [ "$status" -eq 2 ]
    [[ "$stderr" == *"unknown stream: prod"* ]]
    # And no change request is created
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2699010101-mock" ]
}

@test "agentic-eng: scn: Required and valid arguments: with input and --stream but no --agent-tool parameter" {
    # | invocation                                      | requirement                           |
    # | with input and --stream but no --agent-tool parameter | --agent-tool is required             |
    # When Engineer runs the agentic engineering script <invocation>
    run --separate-stderr bash "$REPO_ROOT/scripts/agentic-eng.sh" --stream dev "$AGENTIC_INPUT"
    # Then error indicates <requirement>
    # requirement = --agent-tool is required
    [ "$status" -eq 2 ]
    [[ "$stderr" == *"--agent-tool is required"* ]]
    # And no change request is created
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2699010101-mock" ]
}

@test "agentic-eng: scn: Required and valid arguments: with --agent-tool codex" {
    # | invocation                             | requirement                               |
    # | with --agent-tool "codex"              | --agent-tool must be auggie or claude     |
    # When Engineer runs the agentic engineering script <invocation>
    run --separate-stderr bash "$REPO_ROOT/scripts/agentic-eng.sh" --stream dev --agent-tool codex "$AGENTIC_INPUT"
    # Then error indicates <requirement>
    # requirement = --agent-tool must be auggie or claude
    [ "$status" -eq 2 ]
    [[ "$stderr" == *"unknown agentic tool: codex"* ]]
    # And no change request is created
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2699010101-mock" ]
}
