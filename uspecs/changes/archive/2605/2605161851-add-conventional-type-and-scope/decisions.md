# Decisions

## Uncertainty: where are `type` and `scope` stored in `change.md` so `upr` can read them when composing the PR title and commit message

Decision: Both in YAML frontmatter as `type:` and `scope:` fields

- Pros: structured and machine-readable; `upr` reads them via the existing `md_read_frontmatter_field` helper; heading stays human-readable; type written at `uchange` time, scope added by the agent at construction time, both into the same place
- Cons: two fields to keep consistent with the body; agent has to remember to update frontmatter when scope changes
- Confidence: high

Alternatives:

1. Embed in the change heading: `# Change request: feat(softeng): <title>`
   - Pros: single source of truth; `upr` already extracts "text after `:`" from the heading - minimal extraction logic change; heading already looks like the future merge commit subject
   - Cons: rewrites the heading every time type/scope change; the human title is mixed with the conventional prefix in one string; doesn't fit the "scope decided later, by the agent during construction" decision unless the heading is also rewritten at that point
   - Confidence: medium
2. Type in YAML frontmatter, scope in a dedicated line in `## How` (e.g. a labeled bullet `Scope: softeng`)
   - Pros: scope sits next to References and source-file decisions, which is where the agent decides it during construction; type stays simple in frontmatter
   - Cons: split storage; `upr` has to grep the body for the scope line; brittle to reformatting/renaming
   - Confidence: low
3. Type in frontmatter; scope auto-derived by `upr` at PR time from the most-frequent `uspecs/specs/{domain}/{context}` path appearing in the change folder's files
   - Pros: zero manual scope authoring; aligns scope to what the change actually touches
   - Cons: implicit and hard to override; couples scope to file paths that may not exist for every change; surprising when the agent's intended scope differs from the derived one
   - Confidence: low

## Uncertainty: is `--type` required for `uchange`, and what happens if it's missing or not in the allowed list

Decision: `--type` is required; allowed list enforced by prompt instructions only (no bash validation)

- Pros: every Change Request has a type up front; no validation duplication between bash and the prompt; single source of truth for the allowed list lives in the prompt fragment; easy to extend the list without code changes
- Cons: typos and non-conforming types are not caught at change-creation time; mistakes surface later (in commit log / PR title) for humans who bypass the prompt
- Confidence: user-provided

Alternatives:

1. `--type` is required and `softeng.sh` validates the value against the allowed list, erroring on unknown values
   - Pros: every Change Request is Conventional-Commits-compliant by construction; bad types caught at change-creation time
   - Cons: small CLI parsing addition; allowed list duplicated in bash validator and prompt fragment unless kept in one source
   - Confidence: high
2. `--type` is optional with a default (e.g. `chore`); validated when present
   - Pros: lowest-friction CLI; backward-compatible call sites keep working without changes
   - Cons: `chore` is misleading for actual features/fixes; defaults encourage skipping the deliberate type choice; hides intent in history
   - Confidence: low
3. No `--type` option; the agent infers `type` and writes the `type:` frontmatter field directly (mirroring how `scope:` is set later)
   - Pros: symmetric with `scope` (both authored by the agent into frontmatter); no CLI surface to learn
   - Cons: inferred type may drift from user intent; harder to script/automate; user has no direct override before the file is created
   - Confidence: low

## Uncertainty: exact composition rules for `upr`'s `pr_title` and pre-squash `commit_message` across all combinations of (scope, issue_url, breaking marker)

Decision: Strict Conventional Commits placement; PR title equals pre-squash commit subject; trailers in body; `!` is a separate `breaking:` boolean frontmatter field rather than baked into `type:`

- Pros: clean separation -- `type` stays clean (`feat`), breaking-ness is a dedicated field; easier to query/filter changes by breaking-ness; PR title and merge commit subject identical, so GitHub squash-merge produces a clean log; trailers ordered with project-level reference first (`See change.md`) and issue trailer last (Git convention)
- Cons: extra frontmatter field (`breaking:`) on top of `type:` and `scope:`; three frontmatter fields to keep consistent; the conventional spelling `feat!` does not appear in source-of-truth form
- Confidence: medium

Alternatives:

1. Same placement as chosen, but `!` is baked into `type:` (e.g. `type: feat!`) rather than a separate field
   - Pros: single field for the conventional prefix; the canonical Conventional Commits spelling `feat!` shows up directly in frontmatter; one fewer field to maintain
   - Cons: harder to query "is this change breaking?" programmatically; mixes two concerns (kind and breaking-ness) in one value
   - Confidence: high
2. Same placement as chosen but trailers reversed in the body: `Closes #<issue_id>` first, then `See change.md for details`
   - Pros: `Closes` trailer most prominent; some teams prefer issue closers at the top of the body
   - Cons: violates the Git convention that machine-readable trailers (`Closes #N`, `Co-authored-by:`, `Signed-off-by:`) cluster at the very bottom of the message; tools that parse trailers expect them last
   - Confidence: low
3. Pre-squash commit subject differs from PR title: subject is strict `<type>(<scope>)!: <change_title>` (no `[issue_id]`), PR title keeps `[issue_id]` for visual scannability in GitHub
   - Pros: pre-squash commit is fully Conventional-Commits-compliant for downstream parsers; PR list in GitHub still highlights the ticket
   - Cons: PR title and merge commit subject diverge -- GitHub's squash-merge uses the PR title (with `[issue_id]`) for the merge commit subject, so the strict subject only exists on the feature branch; awkward to test/document
   - Confidence: low

## Uncertainty: what criteria does the prompt give the agent to decide `breaking: true`

Decision: Conservative shape rule extended to UI -- `breaking: true` only when an existing user-facing contract is removed or changed in an incompatible way; contract covers code APIs / CLI surfaces and existing UI screens or workflows. Additive changes (new screens, new optional parameters, new commands or flags) are never breaking.

- Pros: easy to apply with few false positives; covers both code and UI surfaces so the rule fits projects that ship interfaces beyond CLIs/libraries; aligns with the typical "breaking change" definition used by release tooling; agent can answer mechanically by checking whether anything previously valid no longer works
- Cons: misses some config-file changes and default-behavior changes that also break users (under-marks reality); requires the agent to recognize what counts as a UI "workflow" in projects without an explicit UI spec
- Confidence: medium

Alternatives:

1. Conventional Commits FAQ rule: any change that requires users to modify their code, configuration, environment, or invocation to keep working is breaking
   - Pros: aligned with upstream Conventional Commits guidance; captures config/default-behavior cases that the conservative rule misses; semver tooling expects this scope
   - Cons: broader judgement surface; the agent has to reason about all user-visible behavior at construction time, increasing inconsistency between changes
   - Confidence: high
2. Project-specific uspecs rule: `breaking: true` when the change requires modifications to existing Change Folders, prompts, dispatcher templates, or installed plugins to keep working
   - Pros: scoped to this project's actual users; concrete and testable; agent can check against specific file types
   - Cons: not portable to other projects that adopt the same convention; needs revisiting if the project surface changes
   - Confidence: medium
3. Always default to `false`; agents only set `breaking: true` when the user explicitly says so (future `--breaking` flag or explicit wording in the change description)
   - Pros: zero ambiguity; no agent judgement needed
   - Cons: under-marks breaking changes silently; the field becomes near-decorative; defeats automated semver tooling
   - Confidence: low

## Uncertainty: who teaches the AI Agent to derive `--type` from the user's natural-language `uchange` invocation, and where does that instruction live

Note: the original framing assumed `gen-uspecs-market.py` regenerates the `<!-- uspecs:begin -->` block in this repo's `AGENTS.md` / `CLAUDE.md`. Investigation showed that is not the case -- the generator only emits files into a separate marketplace repo, and the block in this repo is hand-maintained. The decision below reflects the corrected picture.

Decision: Update `scripts/templates/actions/uchange.yaml` to add a `--type` derivation rule alongside the existing `--kebab-name` rule, and change the `<!-- uspecs:begin -->` block in `AGENTS.md` / `CLAUDE.md` to reference the yaml directly instead of inlining the uchange-specific rules. The block becomes a single rule: when user input starts with `uchange [options] {other-input}`, read the `raw_text` block in `scripts/templates/actions/uchange.yaml` and follow its instructions, treating `{{dispatch}}` as `run bash bin/softeng.sh action uchange {options}`. The allowed types list lives in the yaml only -- by authoring time `softeng.sh` has already written `type:` verbatim into the frontmatter from `--type`, so the authoring-time prompt (which covers scope derivation and breaking criteria only) does not repeat the list.

- Pros: yaml becomes the single source of truth read at runtime; mirrors the existing `uclarify` reference pattern; no inlined rules in AGENTS.md / CLAUDE.md to drift; future edits to the uchange dispatcher rule are a single-file change; allowed types list lives in exactly one place, with no need for "kept consistent by review" hygiene
- Cons: agent has an extra read step on every `uchange` invocation; agent has to parse the yaml `raw_text:` block rather than markdown; `{{dispatch}}` placeholder needs an in-line expansion note in AGENTS.md so the agent knows what it stands for; creates a temporary inconsistency where `uchange` and `uclarify` follow the reference pattern while other actions stay inlined
- Confidence: medium

Alternatives:

1. Hand-maintain in sync: yaml gets the rule, AGENTS.md / CLAUDE.md get the same rule manually pasted in; two files to keep aligned with no tooling support
   - Pros: no pattern change; agent reads AGENTS.md directly (no extra hop); minimal touch beyond editing three files
   - Cons: manual sync between yaml and the two top-level docs on every future edit; nothing prevents drift; "kept consistent by review" is the only safeguard
   - Confidence: medium
2. Generalize the reference pattern across all actions: change AGENTS.md / CLAUDE.md to reference each action's yaml/md file, retire the per-action inlined rules entirely
   - Pros: full consistency with the `uclarify` pattern; one place per action; substantial cleanup
   - Cons: scope creep beyond Conventional Commits; touches every action's dispatcher in one change; better as a follow-up
   - Confidence: medium
3. Add a paired `uchange.md` alongside `uchange.yaml` (matching the `uclarify.md` pattern); `uchange.yaml` uses the existing `file:` field to point at `uchange.md`; AGENTS.md / CLAUDE.md reference `uchange.md`
   - Pros: agent reads markdown (cleaner than parsing the yaml `raw_text:` block); leverages the existing `file:` mechanism in `load_actions`; one source of truth for both the marketplace generator and the dispatcher
   - Cons: adds a second file per action; bigger structural move than this change's nominal scope
   - Confidence: medium
4. Leave the dispatcher rule alone; have the agent ask the user for `--type` when it's missing
   - Pros: zero template / AGENTS.md changes; no risk of bad inference; explicit user intent
   - Cons: extra round-trip on every `uchange` invocation; defeats the chat-flow ergonomics where one short command kicks off the whole flow
   - Confidence: low
5. Prompt for `--type` interactively in `bin/softeng.sh` when the option is absent
   - Pros: no template changes; works whether the agent or a human runs the script
   - Cons: introduces interactive prompts where the script is currently non-interactive; agent has no tty; inconsistent with `--kebab-name` which is required and not prompted
   - Confidence: low

## Uncertainty: how does `upr` behave when `change.md` has no `type:` frontmatter field (older changes created before this rollout, including the current one)

Decision: Hard fail -- `cmd_action_upr` exits with a clear error pointing at the allowed list and instructing the user to add `type:` to the frontmatter. No fallback, no default. Pre-existing in-flight change folders (including this one) must have `type:` added manually before `upr` can run against them.

- Pros: Conventional Commits classification is guaranteed for every PR going forward; mistakes surface immediately at the call site; no silent omission; consistent with `--type` being required at `uchange` time; matches the spirit of "every change has a deliberate type"
- Cons: pre-existing in-flight change folders need a one-time manual fix; the current change folder needs `type: feat` added before the implementation can dogfood itself; no automatic migration helper
- Confidence: high

Alternatives:

1. Soft fallback: compose the PR title/commit subject without the conventional prefix (current behavior preserved) and print a warning to stderr when `type:` is absent
   - Pros: backward-compatible; old change folders keep working; rollout is non-disruptive
   - Cons: silent omissions accumulate; some PRs land without conventional prefixes; the convention isn't actually enforced
   - Confidence: medium
2. Default to a safe type (`chore`) when `type:` is absent
   - Pros: never fails; everything keeps moving; no manual fixes needed
   - Cons: mislabels feature/fix work as `chore`; defaults hide intent in history; downstream release tooling gets bad data
   - Confidence: low
3. Hard fail plus a one-shot migration helper to retrofit `type:` into existing change folders
   - Pros: same guarantee as the chosen option; smoother transition for repos with many in-flight changes
   - Cons: extra surface to maintain; helper duplicates frontmatter-writing logic; overkill if few in-flight changes exist
   - Confidence: medium
