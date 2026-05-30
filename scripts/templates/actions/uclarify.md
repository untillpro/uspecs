# Clarifications

## Issue types

The clarification process targets four kinds of issues in a specification or artifact:

- Uncertainty: an open question with multiple viable alternatives
- Inconsistency: two or more statements that contradict each other
- Ambiguity: a statement that admits multiple valid interpretations
- Vagueness: a statement that lacks the precision needed to act on

"Issue" is used below as the umbrella term for any of the four.

## Modes

- Interactive (default): present one issue at a time, wait for user input
- Auto (`--auto`): find and resolve three most critical issues without user input

## Start

- Determine the mode: Auto if the user's message contains `--auto`, otherwise Interactive
- Determine the input (see Input)
- Immediately proceed with the mode's steps; do NOT ask the user what to do
- Do NOT confirm or summarize before starting; the first agent output is the options prompt (Interactive) or the integrated decisions plus summary (Auto)

## Input

The agent infers the clarification input from context, applying these rules in order (first match wins):

- If a specific file is referenced in the user's message (named, attached, or otherwise explicitly pointed at), that file is the input -- even when `change.md` is also open or in scope
- Otherwise, if `change.md` is open, attached, or mentioned, it is the input implicitly (`/uclarify change.md`)
- Otherwise the agent asks the user to clarify which file to process

## Decision recording

A decision is recorded only when the clarification target is clearly `change.md` or a spec related to it (a file referenced from `change.md`). When this condition holds, every integrated decision (in either mode) MUST be appended to `decisions.md` located next to `change.md` in the Change Folder. Skipped and cancelled issues are not recorded.

When the condition does not hold (no `change.md` in scope, or the target is unrelated to it):

- Do not write to `decisions.md`
- Inform the user: "Decision integrated. Not recorded: no Change Folder in scope."
- Integration into the target spec/artifact and the review prompt (Interactive mode) are unchanged

The heading uses the specific issue type (`Uncertainty`, `Inconsistency`, `Ambiguity`, or `Vagueness`), not the umbrella term.

The `Alternatives` list MUST contain only the solutions that were NOT chosen. Do not repeat the chosen Decision as an entry in `Alternatives`. If no other solutions were considered, omit the `Alternatives:` heading and its list entirely.

```text
# Decisions: {change request name from change.md}

## {Issue-type}: {short issue statement}

Decision: {chosen solution}

- Pros: ...
- Cons: ...
- Confidence: low | medium | high | user-provided

Alternatives:

1. {other solution name}
   - Pros: ...
   - Cons: ...
   - Confidence: low | medium | high
2. {other solution name}
   - Pros: ...
   - Cons: ...
   - Confidence: low | medium | high
```

For free-form user answers, populate Pros and Cons with the agent's best-effort assessment and set Confidence to `user-provided`.

## Change.md section boundaries

When clarifying a `change.md` `## What` section:

- Treat `## What` as behavior-level change scope: what externally observable behavior changes, which contract/output/workflow is affected, and what behavior must be preserved.
- Do not ask for file names, symbol names, implementation steps, dependency choices, reference links, or exact construction locations just to make `## What` more concrete. Those details are clarified later in `## How`.

## Interactive mode

Terminology:

- Solution: a viable resolution to the issue
- Option: an entry in the numbered list -- either a solution or a control choice (Skip/Cancel)

Steps:

- Identify the most critical issue in the provided input and classify it as one of the four issue types
- Present a numbered list of options
  - For each solution, list tradeoffs and confidence as sub-bullets under explicit labels: `Pros:`, `Cons:`, `Confidence:` (low/medium/high)
  - First option should be the most likely or recommended solution
  - Last options are always
    - "Skip" -- skip the current issue and find the next most critical issue to present options for it
    - "Cancel" -- stop clarification process, do not make any changes
  - After the list, tell the user: "Pick a number, type your own answer, or choose Skip/Cancel"
- Use web search to find relevant information if needed or if the user includes `--web` in their message
  - For technology, architecture, library, or tool choices web search is a must
- After the user picks a numbered option, provides a free-form answer, or chooses Skip/Cancel:
  - If the choice is a numbered solution or a free-form answer, you MUST:
    - Integrate the decision into the relevant specification or artifact files
    - Fix other issues (uncertainty, inconsistency, ambiguity, or vagueness), stale alternatives, and TBD markers caused or made resolvable by this decision, across the input file and any files it references (for `change.md`, this includes the specs it links to)
    - Possibly append an entry to `decisions.md` (see Decision recording)
    - Do not ask follow-up questions about the same issue before integration
  - If the choice is Skip, find the next most critical issue and present options for it
  - If the choice is Cancel, stop -- do not make any changes
- After integration (numbered solution or free-form answer only -- not after Skip or Cancel), present a review prompt with three control choices:
  - "Continue" -- proceed to the next issue
  - "Discuss" -- user provides feedback; revise the spec/artifact integration in place, overwrite the `decisions.md` entry for this issue, then re-show the review prompt
  - "Cancel" -- stop the clarification process; previously integrated decisions remain
  - Free-form input on the review prompt is treated as Discuss with that input as feedback
- Repeat the process until the user chooses Cancel

Example options prompt (uncertainty):

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

Example options prompt (inconsistency):

```text
## Inconsistency: `change.md` says the API returns `userId`, but `api--reqs.md` says it returns `user_id`

1. Standardize on `userId` (camelCase)
   - Pros: matches existing JSON conventions in the repo
   - Cons: requires updating `api--reqs.md` and any downstream consumers
   - Confidence: high
2. Standardize on `user_id` (snake_case)
   - Pros: matches the database column name
   - Cons: diverges from existing JSON conventions
   - Confidence: medium
3. Skip
4. Cancel

Pick a number or type your own answer.
```

Example review prompt:

```text
Decision integrated: pnpm

1. Continue -- proceed to the next issue
2. Discuss -- provide feedback to revise this decision
3. Cancel -- stop clarification process

Pick a number or type your feedback (treated as Discuss).
```

## Auto mode

Activated when the user includes `--auto` in their message.

- Identify the three most critical issues in the provided input and classify each as one of the four issue types
- For each issue, pick the best solution based on available context and web search
- Integrate all three decisions into the relevant specification or artifact files
- Fix other issues (uncertainty, inconsistency, ambiguity, or vagueness), stale alternatives, and TBD markers caused or made resolvable by each decision, across the input file and any files it references (for `change.md`, this includes the specs it links to)
- Append all three entries to `decisions.md` (see Decision recording)
- Report a brief summary to the user (one line per decision: issue type + short statement + chosen solution) and mention that full details are in `decisions.md`
