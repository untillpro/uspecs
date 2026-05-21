# Decisions

## Uncertainty: what IS the "single source of truth" for per-action option lists, and how do downstream consumers read it?

Decision: New `softeng meta options <action>` subcommand backed by a per-action data table inside `softeng.sh`

- Pros: bash is the runtime truth and also the documentation source; the table is the single source consumed by the meta subcommand, the marketplace generator, and the consistency test; no regex parsing of shell from Python; the meta command is reusable by tests and the reviewer skill.
- Cons: the parser arms and the table are co-declared (see follow-up decision on parser model) and rely on the consistency test to stay in sync rather than being structurally identical; adds a generator dependency on invoking bash at build time (already done elsewhere, but a new coupling for this surface).
- Confidence: high

Alternatives:

1. Extract from `cmd_action_*` parser via regex in the generator
   - Pros: smallest code change; no refactor of bash internals; the runtime parser IS the source.
   - Cons: regex parsing of bash is fragile and breaks on stylistic variation; encoding which flags take an argument requires additional heuristics; future parser style changes can silently break extraction.
   - Confidence: medium
2. Structured comment block above each `cmd_action_*`
   - Pros: small, explicit, easy for both Python and bash to read; keeps option metadata adjacent to its parser; minimal refactor.
   - Cons: the comment is still a separate string from the `case` arms, so drift between them is possible; the SoT property is weaker than the chosen option and relies on the consistency test to catch divergence.
   - Confidence: medium
3. Dedicated declarative file consumed by both bash and python
   - Pros: fully declarative; richest format (arity, required, descriptions); language-neutral.
   - Cons: bash must learn to consume the file, otherwise the parser duplicates the data again and the original problem returns; introduces a new artifact category for a small payload.
   - Confidence: medium

## Uncertainty: what to do with the in-script option documentation surfaces (top-of-file `Usage:` block and per-`cmd_action_*` header signature lines)

Decision: Remove both surfaces; keep only the prose in per-function headers describing implementation-level side effects and contracts not covered by scenarios

- Pros: `softeng.sh` is an internal script with no `--help` flag and no runtime reader of either surface, so neither has a programmatic consumer; behavior of every option is already exhaustively specified in the corresponding `*.feature` scenarios, and `softeng meta options <action>` is the discoverable runtime source; removing both reduces the drift surfaces from four to two (parser + yaml `options:`), and the chosen design already collapses those two into one table.
- Cons: maintainers reading `softeng.sh` lose the at-a-glance option list (top of file and above each function) and must run `softeng meta options <action>` or open the feature file for the same information; the in-file landmark for "what does this command take" is gone.
- Confidence: user-provided

Alternatives:

1. Remove only the per-function signature lines; keep the top-of-file `Usage:` block as a quick reference, covered by a consistency test against `meta options`
   - Pros: preserves a single in-file landmark; removes the more redundant per-function copy.
   - Cons: still leaves one prose surface that can drift; needs a dedicated consistency test to stay honest.
   - Confidence: medium
2. Keep both surfaces and let the reviewer skill enforce alignment with the option table
   - Pros: preserves local readability at both locations; no deletions.
   - Cons: leaves two drift surfaces with no programmatic consumer; relies on reviewer attention.
   - Confidence: low
3. Auto-generate both surfaces from the option table at edit time
   - Pros: readability preserved without drift risk.
   - Cons: adds tooling (generator or pre-commit hook) for cosmetic in-file comments; out of proportion to the value.
   - Confidence: low

## Uncertainty: how does each `cmd_action_*` consume the option table — table-driven at runtime, or hand-written `case` arms with a parity test?

Decision: Hand-written `case` arms co-declared with the table; a consistency test asserts they enumerate the same option set and arities

- Pros: smaller per-function refactor — existing `case` arms stay, only the table is added; idiosyncratic per-flag handling (custom error text, conditional shifts, short-flag aliases like `-y`) remains trivial to express; the table is unambiguously the *documented* truth consumed by `meta options`, the marketplace generator, and the test, while the parser stays in its current shape.
- Cons: parser arms and table are two correlated declarations in the same file, which is the failure shape the change is trying to eliminate; the "single source of truth" property is test-time rather than structural — relies on the consistency test running in CI to catch drift instead of preventing it by construction.
- Confidence: user-provided

Alternatives:

1. Table-driven at runtime: a shared helper iterates the action's table and parses `argv` into a known set of variables; per-action `cmd_action_*` keeps only its semantic body
   - Pros: parser and table are the same code path — drift is structurally impossible, no parity test needed; the consistency test collapses into a smoke test of `meta options` per action; adding/renaming a flag is a one-line edit.
   - Cons: bash boilerplate to read tables uniformly (associative arrays of arity, required, value-var-name); option value variables must follow a naming convention (e.g. `opt_<flag>`); short-flag aliases need explicit handling in the table; largest refactor — every `cmd_action_*` body changes shape.
   - Confidence: high
2. Hybrid: a generator emits the `case` arms into `softeng.sh` from the per-action table at build time
   - Pros: parser is mechanically derived from the table; no runtime loop in bash.
   - Cons: introduces a code-generation step into a script that is otherwise hand-edited; the generated section needs sentinel markers and tooling; out of proportion to the payload.
   - Confidence: low
