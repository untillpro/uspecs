# Decisions

## Uncertainty: how should `--no-impl` behave when combined with `--how` or `--plan`

Decision: No-op when alone, error when combined

- Pros: surfaces intent mismatch early; nudges users off `--no-impl`; mirrors the existing `--branch` / `--no-branch` mutual-exclusion idiom in `cmd_action_uchange`
- Cons: more parser logic and a new error path to test; technically breaks BC for any script that combined `--no-impl` with other flags (today such scripts work because `--no-impl` suppresses impl emission unconditionally)
- Confidence: user-provided

Alternatives:

1. Strict no-op (silently ignored regardless of what else is passed)
   - Pros: simplest mental model; matches the "no-op" wording literally; trivial parser; preserves any BC even for scripts that combined flags
   - Cons: silently accepts combinations that look contradictory to a human reader
   - Confidence: high
2. Soft deprecation hint when combined (honored as no-op but prints a stderr warning)
   - Pros: visible without breaking BC; eases future migration
   - Cons: clutters log output; needs a stderr-clean test invariant; contradicts the change.md positioning of `--no-impl` as a preserved future BC partner rather than a deprecation
   - Confidence: low

## Uncertainty: how should `--specs` interact with the new `--how` / `--plan` flags

Decision: Independent contributions (reading A) - `--specs` keeps its filesystem side-effect on its own, spec-tier bullets require `--plan`

- Pros: each flag retains a single responsibility (`--specs` = folder, `--plan` = plan menu); composable; minimal change to the cascade (just flip `impl_maybe`'s source); lets users prep the specs folder up front without committing to a plan
- Cons: the existing `--specs option` scenario in `uchange.feature` has to be split; users who pass only `--specs` expecting the menu (current behavior) will see a behavior change
- Confidence: user-provided

Alternatives:

1. `--specs` implies `--plan` (passing `--specs` automatically turns on `impl_maybe`)
   - Pros: preserves existing `--specs` behavior verbatim; single flag does the obvious thing for users who care about specs
   - Cons: hidden coupling; introduces an implication rule that has to be documented and tested; muddies the "opt-in per artifact" model just established
   - Confidence: medium
2. Decoupled cascade (reading B) - `--specs` alone emits spec-tier bullets without `--plan`
   - Pros: each flag retains its full standalone behavior; existing `--specs option` scenario stays as-is
   - Cons: requires reshaping the `*_maybe` cascade so spec-tier gates depend on `specs_maybe` alone, not `impl_maybe AND specs_maybe`; produces an asymmetric menu (spec-tier bullets without Prov/Constr) that is hard to explain
   - Confidence: low
3. `--specs` becomes a no-op without `--plan` (folder creation also gated on `--plan`)
   - Pros: strictest single-responsibility model
   - Cons: removes the standalone "just create the folder" affordance; rewrites the existing scenario more aggressively than option A
   - Confidence: low

## Uncertainty: how should the agent dispatch derive `--how` / `--plan` from the user's prompt

Decision: Explicit only - no inference, and no new dispatch rule needed. The new flags follow the same implicit convention already governing `--branch` / `--no-branch` / `--no-impl` today: the agent forwards what the engineer typed; only options listed in the yaml's `raw_text` derivation rules are inferred. Only the `options:` line in `scripts/templates/actions/uchange.yaml` is updated to list `--how` and `--plan`; no changes to `raw_text`, `AGENTS.md`, or `CLAUDE.md`.

- Pros: zero new instruction surface; consistent with how `--branch` / `--no-branch` / `--no-impl` are already handled; predictable; no false-positives from heuristic misreads; aligns with the "opt-in, do less by default" framing in Why
- Cons: less ergonomic - users have to learn the flags; departs from the inference pattern used for `--specs` / `--type` / `--issue-url` (though that asymmetry already exists today)
- Confidence: user-provided

Alternatives:

1. Add an explicit "do not infer `--how` or `--plan`" rule to the yaml `raw_text` (and mirror it in AGENTS.md / CLAUDE.md)
   - Pros: makes the no-inference policy visible in the dispatch instructions
   - Cons: redundant - the same outcome already holds for `--branch` / `--no-impl` without such a rule; bloats `raw_text` with guard text; risks the rule drifting out of sync with reality
   - Confidence: medium
2. Infer from natural-language cues (e.g., "with implementation plan" -> `--plan`, "capture the how" -> `--how`)
   - Pros: matches the inference pattern of `--type` / `--specs`; ergonomic for users
   - Cons: heuristics are brittle and ambiguous; silent wrong-inference is hard to debug; opens an endless tail of heuristic tuning
   - Confidence: low
3. Explicit by default plus a single narrowly-documented inference trigger per flag
   - Pros: middle ground; some ergonomics without runaway heuristics; documented triggers are predictable
   - Cons: still produces edge cases; documentation overhead; small DX win for non-zero cognitive cost
   - Confidence: low
