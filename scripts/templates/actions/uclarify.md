# Clarifications

## Modes

- Interactive (default): present one uncertainty at a time, wait for user input
- Auto (`--auto`): find and resolve three most critical uncertainties without user input

## Start

- Determine the mode: Auto if the user's message contains `--auto`, otherwise Interactive
- Determine the input (see Input)
- Immediately proceed with the mode's steps; do NOT ask the user what to do
- Do NOT confirm or summarize before starting; the first agent output is the options prompt (Interactive) or the integrated decisions plus summary (Auto)

## Input

The agent infers the clarification input from context:

- If `change.md` is open, attached, or mentioned in the user's message, it is the input implicitly, consider as the primary source (`/uclarify change.md`)
- If a different file is more specifically referenced, that file is the input
- Otherwise the agent asks the user to clarify which file to process

## Decision recording

A decision is recorded only when the clarification target is clearly `change.md` or a spec related to it (a file referenced from `change.md`). When this condition holds, every integrated decision (in either mode) MUST be appended to `decisions.md` located next to `change.md` in the Change Folder. Skipped and cancelled uncertainties are not recorded.

When the condition does not hold (no `change.md` in scope, or the target is unrelated to it):

- Do not write to `decisions.md`
- Inform the user once, e.g., "Decision integrated. Not recorded: no Change Folder in scope."
- Integration into the target spec/artifact and the review prompt (Interactive mode) are unchanged

Per-decision format (second-level header per entry):

```text
## Uncertainty: <short statement of the uncertainty>

Decision: <chosen solution name>

- Pros: ...
- Cons: ...
- Confidence: low | medium | high | user-provided

Alternatives:

1. <solution name>
   - Pros: ...
   - Cons: ...
   - Confidence: low | medium | high
2. <solution name>
   - Pros: ...
   - Cons: ...
   - Confidence: low | medium | high
```

For free-form user answers, populate Pros and Cons with the agent's best-effort assessment and set Confidence to `user-provided`.

## Interactive mode

Terminology:

- Solution: a viable answer to the uncertainty
- Option: an entry in the numbered list -- either a solution or a control choice (Skip/Cancel)

Steps:

- Identify the most critical uncertainty in the provided input
- Present a numbered list of options
  - For each solution, list tradeoffs and confidence as sub-bullets under explicit labels: `Pros:`, `Cons:`, `Confidence:` (low/medium/high)
  - First option should be the most likely or recommended solution
  - Last options are always
    - "Skip" -- skip the current uncertainty and find the next most critical uncertainty to present options for it
    - "Cancel" -- stop clarification process, do not make any changes
  - After the list, tell the user: "Pick a number, type your own answer, or choose Skip/Cancel"
- Use web search to find relevant information if needed or if the user includes `--web` in their message
  - For technology, architecture, library, or tool choices web search is a must
- After the user picks a numbered option, provides a free-form answer, or chooses Skip/Cancel:
  - If the choice is a numbered solution or a free-form answer, you MUST:
    - Integrate the decision into the relevant specification or artifact files
    - Fix ambiguities, contradictions, stale alternatives, and TBD markers caused or made resolvable by this decision, across the input file and any files it references (for `change.md`, this includes the specs it links to)
    - Append an entry to `decisions.md` (see Decision recording)
    - Do not ask follow-up questions about the same uncertainty before integration
  - If the choice is Skip, find the next most critical uncertainty and present options for it
  - If the choice is Cancel, stop -- do not make any changes
- After integration (numbered solution or free-form answer only -- not after Skip or Cancel), present a review prompt with three control choices:
  - "Continue" -- proceed to the next uncertainty
  - "Discuss" -- user provides feedback; revise the spec/artifact integration in place, overwrite the `decisions.md` entry for this uncertainty, then re-show the review prompt
  - "Cancel" -- stop the clarification process; previously integrated decisions remain
  - Free-form input on the review prompt is treated as Discuss with that input as feedback
- Repeat the process until the user chooses Cancel

Example options prompt:

```text
## Uncertainty: which package manager to use for the new Node service

1. pnpm
   - Pros: fast installs via content-addressable store; matches existing services in the repo
   - Cons: extra tooling to install on dev machines
   - Confidence: high
2. npm
   - Pros: ships with Node, no extra tooling
   - Cons: slower installs; larger node_modules
   - Confidence: medium
3. yarn classic
   - Pros: mature; team has prior experience
   - Cons: in maintenance mode
   - Confidence: low
4. Skip
5. Cancel

Pick a number or type your own answer.
```

Example review prompt:

```text
Decision integrated: pnpm

1. Continue -- proceed to the next uncertainty
2. Discuss -- provide feedback to revise this decision
3. Cancel -- stop clarification process

Pick a number or type your feedback (treated as Discuss).
```

## Auto mode

Activated when the user includes `--auto` in their message.

- Identify the three most critical uncertainties in the provided input
- For each uncertainty, pick the best solution based on available context and web search
- Integrate all three decisions into the relevant specification or artifact files
- Fix ambiguities, contradictions, stale alternatives, and TBD markers caused or made resolvable by each decision, across the input file and any files it references (for `change.md`, this includes the specs it links to)
- Append all three entries to `decisions.md` (see Decision recording)
- Report a brief summary to the user (one line per decision: uncertainty + chosen solution) and mention that full details are in `decisions.md`
