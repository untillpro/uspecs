---
change_id: 2607070818-agentic-engineering-script
type: feat
issue_url: https://untill.atlassian.net/browse/AIR-4444
domains: [prod]
scope: [softeng]
---

# Change request: Agentic engineering script

Refs:

- [AIR-4444: uspecs: script for agentic engineering](./issue-AIR-4444.md)

## Why

Engineers currently drive the uspecs change workflow -- creating a change request, iteratively refining it, and optionally opening a pull request -- one action at a time by hand, which is slow and repetitive for routine work. An orchestration capability that runs the loop from input to completed Construction unattended lets the engineer focus on review instead of sequencing actions.

## What

Adds an agentic engineering orchestration capability to the prod (collaborative software engineering) domain that drives a change from input to completed Construction, optionally opening a pull request:

- Requires input, `--stream` (dev, rc, or release), and `--agent-tool` (auggie or claude); there are no defaults.
- Accepts `--stdin` to read input from stdin instead of a positional argument.
- Accepts `-v` to print issued commands, status, decisions, and summaries with `[agentic-eng]` category prefixes.
- Accepts `--pr` to open a pull request after Construction completes.
- Uses `/uspecs-dev` for the dev stream, `/uspecs-rc` for the rc stream, and `/uspecs` for the release stream.
- Creates a change request from input and stops immediately with a failure status if the working branch or the change folder was not created.
- Runs a loop in which each iteration invokes the selected agentic tool once to advance the change through the uspecs workflow, then re-evaluates the stop conditions.
- Stops the loop as soon as the change folder holds a completed Construction section, when an iteration leaves the change folder unchanged, or at a cap of 40 minutes or 40 iterations -- whichever comes first.
- Opens a pull request only when `--pr` is specified and the loop ends with a completed Construction section -- a `## Construction` section with every checklist item checked `[x]`.
- Without `--pr`, exits successfully on completed Construction without opening a pull request.
- Exits with a non-zero status and a diagnostic message on any other terminal condition, instead of opening a pull request.

## How

- bash script `scripts/agentic-eng.sh`
- System test drives the script end to end with the uspecs actions (`uchange`, the per-iteration agent invocation, and `upr`) replaced by mocks/stubs, so it exercises the control flow -- fail-fast, loop stop conditions, and the Construction gate -- deterministically without a real agent or a real pull request.

## Functional design

- [x] create: [softeng/agentic-eng.feature](../../../../specs/prod/softeng/agentic-eng.feature)
  - Specify input sources, stream, `-v`, `--pr`, loop stops, and PR gate.

## Technical design

- [x] update: [softeng/arch.md](../../../../specs/prod/softeng/arch.md)
  - Document standalone orchestration flow.
  - Show stream-specific `uchange`, `uimpl`, and `upr` delegation.
  - Add `agentic-eng` to examples.

## Construction

- [x] create: [tests/sys/agentic-eng.bats](../../../../../tests/sys/agentic-eng.bats)
  - Mock agent tools and uspecs delegation.
  - Cover stream namespace mapping.
  - Cover stdin input.
  - Cover categorized verbose output.
  - Cover `--pr` gate.
  - Cover validation and loop outcomes.

- [x] create: [scripts/agentic-eng.sh](../../../../../scripts/agentic-eng.sh)
  - Require input, `--stream`, and `--agent-tool`.
  - Support `--stdin` input.
  - Map stream to uspecs namespace.
  - Print categorized verbose trace with `-v`.
  - Gate `upr` on `--pr` and completed Construction.

## Quick start

Drive a change from input to completed Construction with one command:

```bash
scripts/agentic-eng.sh [-v] [--pr] [--stdin] --stream <dev|rc|release> --agent-tool <auggie|claude> [input]
```

- Input, `--stream`, and `--agent-tool` are required; input can be positional or provided with `--stdin`.
- `--stdin` reads all stdin as input and cannot be combined with positional input.
- The optional `-v` flag prints issued commands, status, decisions, and summaries to stderr with `[agentic-eng]` category prefixes.
- The optional `--pr` flag opens a pull request after Construction completes; without it, completed Construction exits successfully without opening a pull request.
- The stream selects the uspecs namespace: `dev` -> `/uspecs-dev`, `rc` -> `/uspecs-rc`, and `release` -> `/uspecs`.
- The script creates the change with `uchange`, then loops the selected tool until the Change Folder has a completed `## Construction` section, stops changing, or reaches the 40-minute / 40-iteration cap.
- Without completed Construction it exits non-zero with a diagnostic message.
