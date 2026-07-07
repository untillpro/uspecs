# Decisions: Agentic engineering script

## Inconsistency: `change.md` states no default agentic tool while AIR-4444 says default is auggie

Decision: Make the agentic tool a required argument (no default)

- Pros: forces an explicit, self-documenting invocation; no hidden tool preference that can drift as tooling changes
- Cons: contradicts the issue's stated default (auggie); every call must pass the flag even for the common case
- Confidence: user-provided

Alternatives:

1. Default to auggie when the tool is omitted
   - Pros: preserves AIR-4444's stated behavior; a one-arg invocation (issueURL only) works
   - Cons: hardcodes a tool preference that may drift as tooling changes
   - Confidence: high
2. Default to claude
   - Pros: aligns with this repo's primary agent host
   - Cons: directly contradicts the issue's stated default; surprising for users expecting auggie
   - Confidence: low

## Vagueness: what makes a Construction section "completed" for the pull-request gate

Decision: Open the pull request only when the change folder holds a `## Construction` section with every checklist item checked `[x]`

- Pros: matches AIR-4444's "Construction section with [x] exists" condition; an unambiguous, machine-checkable gate
- Cons: depends on the construction checklist convention being present and correctly filled in
- Confidence: high

Alternatives:

1. Gate on the mere presence of a `## Construction` heading, regardless of checkboxes
   - Pros: simplest to detect
   - Cons: would open pull requests for incomplete work; contradicts the `[x]` requirement
   - Confidence: low
2. Gate on at least one checked `[x]` item, not necessarily all
   - Pros: closer to a literal reading of "with [x] exists"
   - Cons: could open a pull request while construction items remain unchecked
   - Confidence: medium

## Vagueness: when the refinement loop stops ("stabilizes" was imprecise and redundant)

Decision: Stop the loop as soon as an iteration leaves the change folder unchanged, or when a cap of 40 minutes or 40 iterations -- whichever comes first -- is reached

- Pros: matches the issue's break conditions exactly (unchanged change-folder hash; 40 min / 40 iteration cap); removes the vague "stabilizes" wording
- Cons: an iteration that legitimately produces no file change while work is still pending would end the loop early
- Confidence: high

Alternatives:

1. Keep only the time/iteration cap and ignore the no-change condition
   - Pros: simpler stop logic
   - Cons: wastes iterations after work has converged; contradicts the issue
   - Confidence: low
2. Require N consecutive unchanged iterations before stopping
   - Pros: guards against a transient no-op iteration ending the loop early
   - Cons: adds a parameter the issue does not mention; slower to terminate
   - Confidence: medium

## Ambiguity: the script's observable success/failure contract was undefined

Decision: On any terminal condition without a completed Construction section (including hitting the cap), exit with a non-zero status and a diagnostic message; open the pull request only on success

- Pros: gives the script an unambiguous, scriptable success/failure contract; makes "cap reached without completion" an explicit failure
- Cons: treats "cap reached, work partially done" the same as other failures, with no partial-success signal
- Confidence: high

Alternatives:

1. Always exit zero and report status in text only
   - Pros: never surprises callers with a non-zero exit
   - Cons: unusable in automation or CI that keys off exit status
   - Confidence: low
2. Distinct non-zero codes per failure cause (no branch/folder, cap reached, no Construction)
   - Pros: richer signal for callers
   - Cons: more surface to define and maintain than the issue asks for
   - Confidence: medium

## Uncertainty: whether a completed Construction section stops the loop early

Decision: Stop the loop as soon as the change folder holds a completed Construction section, in addition to the no-change and 40-minute / 40-iteration caps

- Pros: stops as soon as the work is demonstrably done, saving iterations and time; directly serves the unattended-efficiency goal in `## Why`
- Cons: adds a break condition beyond the two AIR-4444 lists; a section marked complete prematurely would end the loop early
- Confidence: medium

Alternatives:

1. Keep only the issue's two break conditions (no-change, cap) and check Construction only after the loop ends
   - Pros: matches AIR-4444's structure literally
   - Cons: can burn extra iterations after construction is already complete
   - Confidence: medium
2. Stop only on the cap; ignore both the no-change and Construction-complete conditions
   - Pros: simplest loop logic
   - Cons: always runs to the cap; wasteful and contradicts the issue
   - Confidence: low

## Ambiguity: what a single loop iteration executes

Decision: Each iteration invokes the selected agentic tool once to advance the change through the uspecs workflow, then re-evaluates the stop conditions

- Pros: makes the loop body observable and matches "run uspecs in a loop"; gives the no-change comparison a well-defined per-iteration unit
- Cons: leaves the exact uspecs action(s) invoked per pass to `## How` and construction
- Confidence: high

Alternatives:

1. Run the full uspecs pipeline (clarify -> design -> construct) to completion each iteration
   - Pros: fewer, higher-level iterations
   - Cons: a single iteration could run very long, undermining the per-iteration cap and the no-change check
   - Confidence: low
2. Leave the per-iteration action unspecified
   - Pros: maximum flexibility
   - Cons: the no-change break condition has no well-defined unit to compare against
   - Confidence: low

## Vagueness: what "System test, uspecs mocked" means

Decision: The system test drives the script end to end with the uspecs actions (`uchange`, the per-iteration agent invocation, `upr`) replaced by mocks/stubs, asserting the script's control flow -- fail-fast, loop stop conditions, and the Construction gate -- deterministically without a real agent or a real pull request

- Pros: makes the test's scope and boundaries explicit; deterministic and cheap; no external side effects
- Cons: mocks can drift from the real action contracts, so integration gaps may go uncaught
- Confidence: high

Alternatives:

1. End-to-end test against the real uspecs actions and a real agent
   - Pros: highest fidelity
   - Cons: slow, non-deterministic, requires an agent, and creates real branches/pull requests
   - Confidence: low
2. Unit tests of individual functions only
   - Pros: fast and focused
   - Cons: does not exercise the orchestration/control flow the script exists to provide
   - Confidence: medium
