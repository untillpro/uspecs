# uspecs - avoid lengthy descriptions in sections

Especially for "create"

```markdown
## Functional design

- [ ] create: [softeng/agentic-eng.feature](../../specs/prod/softeng/agentic-eng.feature)
  - Feature Specification for the agentic engineering orchestration workflow: driving a change from an issue URL to a pull request with a required agentic-tool argument (`auggie` or `claude`), covering tool-argument validation, fail-fast when the branch or change folder is not created, the bounded refinement loop and its stop conditions (Construction complete, no change to the Change Folder, or the 40-minute / 40-iteration cap), the completed-Construction pull-request gate, and the non-zero failure exit with a diagnostic message; reference the existing [uchange.feature](../../specs/prod/softeng/uchange.feature) and [upr.feature](../../specs/prod/softeng/upr.feature) for the delegated change-creation and pull-request steps instead of restating their scenarios

## Technical design

- [ ] update: [softeng/arch.md](../../specs/prod/softeng/arch.md)
  - update: Overview to add `agentic-eng` as an exception to the generic action pattern (alongside `uclarify`) -- a standalone `scripts/agentic-eng.sh` that `👤 Engineer` runs directly, which drives `⚙️ AIAgent` in a loop rather than being invoked by it
  - add: "Agentic engineering orchestration flow" section under Key flows -- a sequence diagram covering issue-to-PR orchestration: delegate to `uchange`, fail-fast on a missing branch or Change Folder, the bounded loop that invokes the selected agentic tool (`auggie` or `claude`) once per iteration with its stop conditions (completed Construction section, no change to the Change Folder, or the 40-minute / 40-iteration cap), and the terminal branch to `upr` on a completed Construction section or a non-zero exit with a diagnostic message otherwise; follow the existing flow-section convention by ending with a Key artifacts list linking the `scripts/agentic-eng.sh` script and the `agentic-eng.feature` functional spec
  - add: `agentic-eng` entry to the Examples list (dispatch: `scripts/agentic-eng.sh`; input: issue URL and agentic tool `auggie` or `claude`; output: pull request, or non-zero exit with a diagnostic) 

## Construction

- [ ] create: [tests/e2e/agentic-eng.bats](../../../tests/e2e/agentic-eng.bats)
  - Bats system test that drives `scripts/agentic-eng.sh` end to end, following the [tests/e2e/deliver.bats](../../../tests/e2e/deliver.bats) style (`set -Eeuo pipefail`, `load 'helpers'`, assert `$status` and `$output`)
  - Replace the agentic tool (`auggie`/`claude`) with a PATH-shim mock whose scripted responses deterministically mutate the Change Folder (create and complete a `## Construction` section) and record when the `upr` action is requested, so `uchange`, the per-iteration agent invocation, and `upr` run without a real agent and without creating a real pull request
  - Make the time cap injectable/overridable so the cap path is exercised without waiting 40 minutes
  - Cover, mirroring [agentic-eng.feature](../../specs/prod/softeng/agentic-eng.feature): loop reaches a completed Construction section -> `upr` requested and exit status 0; loop ends on an unchanged Change Folder without a completed Construction -> `upr` not requested, non-zero exit with a diagnostic; loop ends at the iteration cap without a completed Construction -> `upr` not requested, non-zero exit; each iteration invokes the tool exactly once; fail-fast when the branch or Change Folder is not created; argument validation (missing issue URL, missing tool, unknown tool `codex`); both `auggie` and `claude` accepted

- [ ] create: [scripts/agentic-eng.sh](../../../scripts/agentic-eng.sh)
  - Executable orchestration script (`set -Eeuo pipefail`, shellcheck-clean) that drives a change from an issue URL to a pull request; follow the bash conventions used by [scripts/deliver.sh](../../../scripts/deliver.sh); it invokes the selected agentic tool headlessly to run the uspecs actions and inspects git and Change-Folder state between invocations
  - Argument parsing: require `<issue-url>` and a `<tool>` of `auggie` or `claude`; reject a missing issue URL, a missing tool, or an unknown tool with a diagnostic and a non-zero exit; there is no default tool
  - Change creation: invoke the tool to run `uchange {issue-url}`, then verify the working branch and Change Folder were created, else fail fast with a diagnostic and a non-zero exit before the loop starts
  - Bounded loop: each iteration invokes the tool once to advance the change; after each iteration re-evaluate the stop conditions and break on a completed `## Construction` section, an unchanged Change Folder (its hash equals the previous iteration's), or the cap of 40 minutes or 40 iterations, whichever comes first
  - Construction gate: detect a `## Construction` section whose checklist items are all checked `[x]`; on success invoke the tool to run `upr`; otherwise exit with a non-zero status and a diagnostic message without opening a pull request

```

## Rules

- New `create` items should use a short generic description that names the artifact type, purpose, and the source specs or files to follow; do not restate all expected content in the section item.
- Small `update` items should be precise: name the target section, symbol, scenario, or behavior, and describe the exact change in one short subitem.
- Large `update` items should be compacted: summarize the outcome and reference the following specs, examples, or artifacts for detail instead of listing every scenario, branch, or implementation step.
- Threshold: treat an item as large when its description needs more than 3 subitems, touches more than 3 distinct concerns, or would require more than 2 wrapped lines of prose in a single subitem.
- When an item crosses the threshold, split it into separate todos only if the pieces are independently actionable; otherwise keep one compact todo and move detail to the referenced specification.
- Section items should answer "what artifact changes and why" briefly; detailed acceptance criteria, rationale, edge cases, and delegated behavior belong in the referenced spec or design artifact.

## Compacted examples

```markdown
## Functional design

- [ ] create: [softeng/agentic-eng.feature](../../specs/prod/softeng/agentic-eng.feature)
  - Feature Specification for agentic engineering orchestration; cover issue-to-PR flow and reference `uchange.feature` / `upr.feature` for delegated steps

## Technical design

- [ ] update: [softeng/arch.md](../../specs/prod/softeng/arch.md)
  - update: document `agentic-eng` as a direct script-driven orchestration exception to the generic action pattern
  - add: compact Key flows coverage for agentic engineering orchestration, with details aligned to `agentic-eng.feature`
  - add: `agentic-eng` to Examples

## Construction

- [ ] create: [tests/e2e/agentic-eng.bats](../../../tests/e2e/agentic-eng.bats)
  - Bats e2e coverage for `scripts/agentic-eng.sh`; follow `tests/e2e/deliver.bats` style and `agentic-eng.feature` scenarios

- [ ] create: [scripts/agentic-eng.sh](../../../scripts/agentic-eng.sh)
  - Executable orchestration script for issue-to-PR agentic engineering; follow `scripts/deliver.sh` conventions and `agentic-eng.feature`
```

## sections

- uspecs-sec-domains
- uspecs-sec-fd
- uspecs-sec-prov
- uspecs-sec-td
- uspecs-sec-constr

## Findings

1. **Construction conflict:** [.tmp/worklog.md](C:/workspaces/work/uspecs/.tmp/worklog.md:41) says all new `create` items should use one short generic description, but Construction currently requires multiple create subitems: Purpose, key functions/classes/components, and tests ([SKILL.md](C:/workspaces/work/uspecs/.claude/skills/uspecs-sec-constr/SKILL.md:17)).  
   Recommendation: make the shared rule override the old Construction pattern, or phrase it as “create items should usually use one short subitem; add more only when the target is not sufficiently constrained by referenced specs.”

2. **Provisioning fit is weak:** “reference the following specs or files” does not naturally fit Provisioning, where the useful reference may be a CLI command, vendor docs, package name, config file, or current OS rule ([SKILL.md](C:/workspaces/work/uspecs/.claude/skills/uspecs-sec-prov/SKILL.md:17)).  
   Recommendation: say “source specs, examples, commands, docs, or artifacts” instead of only “specs or files.”

3. **Threshold is workable, but should apply to item detail, not section structure:** [.tmp/worklog.md](C:/workspaces/work/uspecs/.tmp/worklog.md:44) is good for detecting bloated subitems. It should not prevent Construction from grouping with `###` when items span 3+ dependency categories ([SKILL.md](C:/workspaces/work/uspecs/.claude/skills/uspecs-sec-constr/SKILL.md:25)).

Suggested Shared Wording:

```md
- New `create` items should use a short description that names the artifact type, purpose, and the source specs, examples, commands, docs, or artifacts to follow; do not restate all expected content in the section item.
- Small `update` items should be precise: name the target section, symbol, scenario, configuration, or behavior, and describe the exact change in one short subitem.
- Large items should be compacted: summarize the intended outcome and reference the following specs, examples, commands, docs, or artifacts for detail instead of listing every scenario, branch, or implementation step.
- Treat an item as large when it needs more than 3 subitems, touches more than 3 distinct concerns, or would require more than 2 wrapped lines of prose in a single subitem.
- Split a large item only when the pieces are independently actionable; otherwise keep one compact todo and move detail to the referenced artifact.
```

This fits `uspecs-sec-domains`, `uspecs-sec-fd`, `uspecs-sec-td`, and mostly fits `uspecs-sec-prov`. For `uspecs-sec-constr`, you’ll need to intentionally replace or soften the current “create uses multiple subitems” rule.