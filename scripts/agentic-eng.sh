#!/usr/bin/env bash
set -Eeuo pipefail

# agentic-eng.sh -- drive a change from input to optional pull request.
#
# Runs the uspecs change workflow unattended by driving a selected
# agentic tool (auggie or claude) in a bounded loop:
#   1. create the change from input (uchange), then fail fast if the working
#      branch or the Change Folder was not created;
#   2. loop, invoking the tool once per iteration to advance the change, until a
#      completed `## Construction` section, an unchanged Change Folder, or the
#      iteration / time cap (whichever comes first);
#   3. when a completed Construction section is present, open a pull request
#      (upr) only if --pr was specified; without completed Construction, exit
#      non-zero with a diagnostic.
#
# Usage:
#   agentic-eng.sh [-v] [--pr] [--stdin] --stream <dev|rc|release> --agent-tool <auggie|claude> [input]
#
# All arguments are required; there is no default stream or tool.
# Use -v to print categorized commands, status, decisions, and summaries to stderr.
# Use --pr to open a pull request after Construction completes.
# Use --stdin to read input from stdin instead of a positional argument.
#
# The selected tool is invoked headlessly, once per step, to run the namespaced
# uspecs commands. dev and rc use /uspecs-{stream}; release uses /uspecs:
#   auggie -p -q "<command>"
#   claude -p    "<command>"
#
# Testing overrides (environment):
#   AGENTIC_ENG_MAX_ITERS    iteration cap (default 40)
#   AGENTIC_ENG_MAX_SECONDS  time cap in seconds (default 2400 = 40 minutes)

usage() {
  echo "usage: $(basename "$0") [-v] [--pr] [--stdin] --stream <dev|rc|release> --agent-tool <auggie|claude> [input]" >&2
}

die() { # die <exit-code> <message...>
  local code="$1"; shift
  echo "agentic-eng: $*" >&2
  exit "$code"
}

vlog() {
  local category="$1"; shift
  if [ "$VERBOSE" = 1 ]; then
    echo "[agentic-eng] [$category] $*" >&2
  fi
}

MAX_ITERS="${AGENTIC_ENG_MAX_ITERS:-40}"
MAX_SECONDS="${AGENTIC_ENG_MAX_SECONDS:-2400}"

# --- Arguments ---------------------------------------------------------------
VERBOSE=0
OPEN_PR=0
READ_STDIN=0
STREAM=""
AGENT_TOOL=""
INPUT=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -v)
      VERBOSE=1
      shift
      ;;
    --pr)
      OPEN_PR=1
      shift
      ;;
    --stdin)
      READ_STDIN=1
      shift
      ;;
    --stream)
      if [ "$#" -lt 2 ]; then
        usage
        die 2 "--stream requires a value (dev, rc, or release)"
      fi
      STREAM="$2"
      shift 2
      ;;
    --agent-tool)
      if [ "$#" -lt 2 ]; then
        usage
        die 2 "--agent-tool requires a value (auggie or claude)"
      fi
      AGENT_TOOL="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      usage
      die 2 "unknown option: $1"
      ;;
    *)
      if [ -n "$INPUT" ]; then
        usage
        die 2 "unexpected extra argument: $1"
      fi
      INPUT="$1"
      shift
      ;;
  esac
done

if [ "$#" -gt 0 ]; then
  while [ "$#" -gt 0 ]; do
    if [ -n "$INPUT" ]; then
      usage
      die 2 "unexpected extra argument: $1"
    fi
    INPUT="$1"
    shift
  done
fi

if [ "$READ_STDIN" = 1 ]; then
  if [ -n "$INPUT" ]; then
    usage
    die 2 "--stdin cannot be used with positional input"
  fi
  INPUT="$(cat)"
fi

if [ -z "$INPUT" ]; then
  usage
  if [ "$READ_STDIN" = 1 ]; then
    die 2 "stdin input is empty"
  fi
  die 2 "input is required"
fi
if [ -z "$STREAM" ]; then
  usage
  die 2 "--stream is required (dev, rc, or release)"
fi
case "$STREAM" in
  dev | rc) USPECS_NS="/uspecs-$STREAM" ;;
  release) USPECS_NS="/uspecs" ;;
  *)
    usage
    die 2 "unknown stream: $STREAM (expected dev, rc, or release)"
    ;;
esac
if [ -z "$AGENT_TOOL" ]; then
  usage
  die 2 "--agent-tool is required (auggie or claude)"
fi
case "$AGENT_TOOL" in
  auggie | claude) ;;
  *)
    usage
    die 2 "unknown agentic tool: $AGENT_TOOL (expected auggie or claude)"
    ;;
esac

vlog status "starting"
vlog status "input: $INPUT"
vlog status "stream: $STREAM"
vlog status "namespace: $USPECS_NS"
vlog status "agent-tool: $AGENT_TOOL"
vlog status "open-pr: $([ "$OPEN_PR" = 1 ] && echo yes || echo no)"
vlog status "max-iters: $MAX_ITERS"
vlog status "max-seconds: $MAX_SECONDS"

# --- Helpers -----------------------------------------------------------------

# run_agent <command>: invoke the selected tool once, headlessly, to run a
# stream-specific uspecs command (e.g. "/uspecs-dev:uchange <input>").
run_agent() {
  case "$AGENT_TOOL" in
    auggie)
      vlog command "auggie -p -q \"$1\""
      auggie -p -q "$1"
      ;;
    claude)
      vlog command "claude -p \"$1\""
      claude -p "$1"
      ;;
  esac
}

# list_change_folders: active (non-archive) Change Folders, one per line, sorted.
list_change_folders() {
  find uspecs/changes -mindepth 1 -maxdepth 1 -type d ! -name archive 2>/dev/null | sort
}

# hash_change_folder <dir>: content hash of a Change Folder (paths + contents).
hash_change_folder() {
  find "$1" -type f -exec sha256sum {} + 2>/dev/null | sha256sum | cut -d' ' -f1
}

# construction_complete <change-folder>: succeed when a plan file holds a
# `## Construction` section with at least one checked item and no unchecked item.
construction_complete() {
  local cf="$1" file
  for file in "$cf/impl.md" "$cf/change.md"; do
    [ -f "$file" ] || continue
    if awk '
        /^## / { inc = ($0 ~ /^## Construction([[:space:]]|$)/) }
        inc && /^[[:space:]]*- \[ \]/  { unchecked = 1 }
        inc && /^[[:space:]]*- \[[xX]\]/ { checked = 1 }
        END { exit !(checked && !unchecked) }
      ' "$file"; then
      return 0
    fi
  done
  return 1
}

# --- 1. Create the change ----------------------------------------------------
before_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
before_folders="$(list_change_folders)"
vlog status "creating change from input"

run_agent "${USPECS_NS}:uchange $INPUT"

after_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
after_folders="$(list_change_folders)"

new_folders="$(comm -13 <(printf '%s\n' "$before_folders") <(printf '%s\n' "$after_folders"))"
CF="${new_folders%%$'\n'*}"

if [ -z "$CF" ]; then
  vlog decision "fail fast: uchange did not create a Change Folder"
  vlog summary "stop-reason: no-change-folder"
  vlog summary "pull-request: not opened"
  die 1 "uchange did not create a Change Folder"
fi
if [ -z "$after_branch" ] || [ "$after_branch" = "$before_branch" ]; then
  vlog decision "fail fast: uchange did not create a working branch"
  vlog summary "stop-reason: no-working-branch"
  vlog summary "change-folder: $CF"
  vlog summary "pull-request: not opened"
  die 1 "uchange did not create a working branch"
fi
vlog status "change-folder: $CF"
vlog status "branch: $after_branch"

# --- 2. Refinement loop ------------------------------------------------------
start_ts="$(date +%s)"
iter=0
prev_hash=""
stop_reason="itercap"

while :; do
  if [ "$iter" -ge "$MAX_ITERS" ]; then
    stop_reason="itercap"
    vlog decision "stop: iteration cap $MAX_ITERS reached"
    break
  fi
  iter=$((iter + 1))
  vlog status "iteration $iter/$MAX_ITERS started"

  run_agent "${USPECS_NS}:uimpl"

  if construction_complete "$CF"; then
    stop_reason="construction"
    vlog decision "stop: Construction complete"
    break
  fi

  cur_hash="$(hash_change_folder "$CF")"
  if [ -n "$prev_hash" ] && [ "$cur_hash" = "$prev_hash" ]; then
    stop_reason="nochange"
    vlog decision "stop: Change Folder unchanged"
    break
  fi
  prev_hash="$cur_hash"
  vlog status "iteration $iter changed Change Folder hash to $cur_hash"

  if [ "$(($(date +%s) - start_ts))" -ge "$MAX_SECONDS" ]; then
    stop_reason="timecap"
    vlog decision "stop: time cap ${MAX_SECONDS}s reached"
    break
  fi
done

# --- 3. Gate optional PR on a completed Construction section ------------------
if construction_complete "$CF"; then
  if [ "$OPEN_PR" = 1 ]; then
    vlog decision "open PR: --pr specified"
    run_agent "${USPECS_NS}:upr"
    vlog summary "stop-reason: $stop_reason"
    vlog summary "iterations: $iter"
    vlog summary "change-folder: $CF"
    vlog summary "pull-request: opened"
    echo "agentic-eng: opened pull request for $CF"
  else
    vlog decision "skip PR: --pr not specified"
    vlog summary "stop-reason: $stop_reason"
    vlog summary "iterations: $iter"
    vlog summary "change-folder: $CF"
    vlog summary "pull-request: not opened"
    echo "agentic-eng: completed Construction in $CF; pull request not opened (--pr not specified)"
  fi
  exit 0
fi

vlog decision "fail: stop reason is $stop_reason"
vlog summary "stop-reason: $stop_reason"
vlog summary "iterations: $iter"
vlog summary "change-folder: $CF"
vlog summary "pull-request: not opened"
die 1 "loop ended ($stop_reason) without a completed Construction section in $CF"
