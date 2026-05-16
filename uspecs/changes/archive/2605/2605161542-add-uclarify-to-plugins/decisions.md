# Decisions

## Uncertainty: should `uclarify` dispatch through `softeng.sh` like other actions

Decision: No `softeng.sh` dispatch; the action template body is the full plugin command/skill

- Pros: matches the nature of the action (pure agent-side interactive flow with no shell-side prep or state); single source for the body; aligns with the existing local skill content shape
- Cons: introduces a second dispatch model alongside the uniform `softeng.sh action ...` pattern; AGENTS.md / CLAUDE.md execution rule needs a carve-out; no bats system test in the existing `softeng.sh-action-*.bats` family
- Confidence: user-provided

Alternatives:

1. Dispatch through `softeng.sh` with a minimal `cmd_action_uclarify`, mirroring `cmd_action_uversion`
   - Pros: uniform dispatch with every other action; AGENTS.md routing rule unchanged; fits the existing bats system test pattern
   - Cons: extra indirection for a command with no shell-side work; risks duplicating the action body between `scripts/templates/actions/uclarify.md` and `bin/prompts/instr_uclarify.md`
   - Confidence: medium
2. Hybrid: no-op `cmd_action_uclarify` that only emits a log header, with the action template body remaining the single source of truth
   - Pros: uniform shell entry without body duplication
   - Cons: ceremony with no functional purpose
   - Confidence: low

## Uncertainty: where does the description for `uclarify` come from

Decision: Create `uspecs/specs/prod/softeng/uclarify.feature` so `read_feature_description` resolves the description from `Feature: ...` like every other action

- Pros: uniform with all other actions; zero changes to `load_actions` / schema; existing tests and tooling work unchanged; opens the door to a real spec later
- Cons: requires a feature file for an action whose semantics live in the action body markdown; risks divergence between `.feature` title and `uclarify.md`
- Confidence: user-provided

Alternatives:

1. Extend the action YAML schema with an optional `description` field that overrides the feature-file lookup
   - Pros: avoids a stub `.feature` file; localizes uclarify metadata in `uclarify.yaml`
   - Cons: breaks the "every action has a feature spec" invariant; adds a second metadata path
   - Confidence: medium
2. Read description from front-matter at the top of `scripts/templates/actions/uclarify.md`
   - Pros: single-source metadata-with-body; closest to the current SKILL.md layout
   - Cons: more parsing in `load_actions`; mixes two metadata mechanisms; diverges from convention
   - Confidence: medium

## Uncertainty: what happens to `.claude/skills/uclarify/SKILL.md` after the move

Decision: `git mv` the file to `scripts/templates/actions/uclarify.md`; the old path is removed, history is preserved, and the AGENTS.md / CLAUDE.md carve-out becomes the source-repo trigger in place of Claude's skill discovery

- Pros: single canonical body; no divergence between source-repo skill and plugin source; preserves git history through the relocation; action template tree stays agent-agnostic
- Cons: loses Claude's native skill discovery in the source repo (no slash-command); trigger is purely through the AGENTS.md / CLAUDE.md rule
- Confidence: user-provided

Alternatives:

1. Keep `.claude/skills/uclarify/SKILL.md` canonical; `scripts/templates/actions/uclarify.yaml` references it via a relative `file:` path; loader strips skill front-matter
   - Pros: source-repo Claude skill discovery continues to work; one body source
   - Cons: action template reaches into `.claude/skills/`; layering inversion; loader gains front-matter stripping logic
   - Confidence: low
2. Two copies kept in sync: canonical at `scripts/templates/actions/uclarify.md`; regenerated `.claude/skills/uclarify/SKILL.md` for source-repo Claude
   - Pros: source repo retains slash-command discovery; canonical body in the actions tree
   - Cons: extra sync step or generated artifact in the repo; staleness risk; new tooling
   - Confidence: medium

## Uncertainty: how is the AGENTS.md / CLAUDE.md carve-out for `uclarify` worded

Decision: Add a separate top-level rule above the existing dispatch rule in the `<!-- uspecs:begin -->` block: when user input starts with `uclarify [options] {other-input}`, read `scripts/templates/actions/uclarify.md` and follow its instructions, treating `{other-input}` as the clarification input. `uclarify` is not added to the "Available commands" list, which keeps enumerating only `softeng.sh`-dispatched actions

- Pros: cleanly separates the two dispatch models; existing rule stays untouched; precedence is explicit (uclarify rule first); "Available commands" remains a coherent list of shell-dispatched actions
- Cons: source-repo users must read two rules to know what is available; "Available commands" no longer enumerates every supported trigger
- Confidence: user-provided

Alternatives:

1. Add `uclarify` to "Available commands" with a "For uclarify" sub-block overriding the dispatch
   - Pros: single Available commands list; mirrors existing "For uchange" sub-block pattern
   - Cons: "For {action}" sub-blocks today describe argument parsing, not dispatch deviations; mixes two concerns in one convention
   - Confidence: medium
2. Generalize the dispatch rule to be action-dependent (dispatched list vs. body-actions list)
   - Pros: extensible if more body-only actions appear later; both models documented in one rule
   - Cons: heavier rewrite; speculative generality for a single body-only action
   - Confidence: low

## Uncertainty: what content goes into `uspecs/specs/prod/softeng/uclarify.feature`

Decision: Minimal conventional content - `Feature:` title, one-line description, and one happy-path `Scenario` per mode (Interactive and Auto)

- Pros: matches the convention of other action feature files without overcommitting; covers the headline behavior of both modes; cheap to extend later
- Cons: doesn't cover decision recording, skip/cancel, or web search; still requires some Gherkin authoring
- Confidence: user-provided

Alternatives:

1. Full feature spec with scenarios for Interactive and Auto modes, decision recording, and skip/cancel
   - Pros: full functional-design coverage; gives reviewers something concrete to validate against
   - Cons: more authoring; risks duplicating wording from `scripts/templates/actions/uclarify.md`; interactive flows are awkward in Gherkin
   - Confidence: medium
2. Title-only stub: `Feature:` line + description, no `Scenario`
   - Pros: minimum content to satisfy `read_feature_description`; defers spec work
   - Cons: breaks the "every action has scenarios" convention; reviewer cannot tell what uclarify does from the spec
   - Confidence: low
