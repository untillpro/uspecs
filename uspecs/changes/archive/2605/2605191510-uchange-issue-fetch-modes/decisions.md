# Decisions

## Uncertainty: should issue-related scenarios be relocated into a new `issue-handling.feature`, or stay in their natural home features with a cross-reference hub?

Decision: Scenarios stay in their natural home features (`uchange.feature`, `upr.feature`, `usync.feature`). A new `uspecs/specs/prod/softeng/issue-handling.feature` is created as a zero-scenario hub whose `Feature:` description text lists each issue-related scenario with a one-line summary and a relative link.

- Pros: avoids fragmenting `Scenario Outline`s that mix issue and non-issue Examples rows (notably `upr.feature`'s commit-message table); keeps scenarios next to the action they constrain; no `Background:` exclusion clauses needed; readers find each scenario in its home feature and discover the cross-action surface via the hub; significantly less FD churn than full relocation
- Cons: hub is non-idiomatic Gherkin (Feature with zero scenarios); contributors must remember to update the hub when adding new issue-related scenarios; living-docs tools may flag the empty feature
- Confidence: user-provided

Alternatives:

1. `issue-handling.md` overview document (markdown, not Gherkin) acting as the hub.
   - Pros: avoids the "Feature with no Scenarios" awkwardness; markdown is the natural format for an index document; link syntax is native
   - Cons: introduces a new spec-file pattern (overview/index document) that does not yet exist under `uspecs/specs/`
   - Confidence: medium
2. Full relocation: move all issue scenarios into `issue-handling.feature`; slim down the three home features and add `Background:` exclusion clauses.
   - Pros: maximum cohesion -- all issue behaviour in one file; existing features become smaller and more focused
   - Cons: breaks up `Scenario Outline` Examples tables (especially `upr.feature`'s commit-message table); creates duplicate setup steps in the relocated scenarios; reviewers have to jump between files to reason about each action's full behaviour
   - Confidence: medium
3. No hub at all; just add "See also" comments at the top of each feature pointing to the others.
   - Pros: smallest change; no new files
   - Cons: no single entry point for the cross-action concept; the regression that started this CR (uchange dropping `issue.md` creation) is exactly the kind of cross-action drift a hub would have surfaced
   - Confidence: low

## Uncertainty: is `## Context` always present in the new shape, or only when the change has a fetchable issue reference?

Decision: `## Context` is created only when the change has a fetchable issue reference. The `change.md` body therefore has two shapes:

- No issue reference: existing `## Why` + `## What` (unchanged)
- Fetchable issue reference: `## Context` replaces `## Why` + `## What`; 2-3 engineer-written sentences distilling the issue followed by `See [issue.md](issue.md) for the originating ticket.` when `issue.md` is created (otherwise just the engineer-written distillation)

Optional `## How` (existing `--how` flag semantics) applies to both shapes. `cmd_action_upr` recognises `## Context` (issue case) or `## Why`/`## What` (non-issue case and archived files).

- Pros: zero churn for engineers creating non-issue changes (no new section to author from a blank slate); `## Context` becomes a precise, dedicated "issue distillation" section rather than a catch-all "always present" header; the engineer is only asked to write distinct content when there is actually something to distil (the issue body)
- Cons: two body shapes increase the matrix `upr` and downstream tooling must handle (mitigated by keeping the regex inclusive); engineers cannot easily migrate a non-issue change to an issue change later without renaming sections
- Confidence: user-provided

Alternatives:

1. `## Context` always present (one body shape).
   - Pros: simplest tooling -- one regex, one artdef; uniform PR body shape
   - Cons: engineers must author motivation/scope from a blank slate even for trivial non-issue changes; redundant with the H1 change title for small changes
   - Confidence: medium
2. Drop `## Why` + `## What` entirely; emit only H1 + frontmatter + optional `## How` when no issue is provided.
   - Pros: very lean for non-issue changes; the H1 carries the framing
   - Cons: no place for motivation when there is no issue; PR body becomes near-empty for non-issue changes; loses information that today goes into `## Why`
   - Confidence: low

## Uncertainty: how does `uchange` learn whether an issue URL is "fetchable" (drives the `## Context` vs `## Why`+`## What` body shape and the fetch instruction)?

Decision: Add a binary `--fetchable` CLI flag to `uchange`. The AI Agent (which knows its skills, MCP integrations, and project rules in `AGENTS.md`/`CLAUDE.md`) decides and passes the flag when it can fetch the issue. Presence means "fetch and use `## Context`"; absence means "do not fetch and use `## Why` + `## What`". Validation: `--fetchable` requires an issue reference; passing it without `--issue-url` errors out. `issue_url` is always recorded in frontmatter when provided, regardless of the flag, so `upr` continues to emit `[<issue_id>]` and `Closes #<issue_id>` for both shapes.

- Pros: removes the ambiguity of "fetchable issue reference" -- the trigger is an explicit, deterministic CLI signal; clean separation between policy (who/how the agent decides) and mechanism (`uchange` consumes the answer); aligns with the dominant boolean-flag pattern in `uchange.feature` (`--how`, `--plan`, `--specs`, `--no-impl` are all presence-only); collapses the validation matrix into one Outline + one edge case; both shapes preserve `issue_url` in frontmatter so downstream actions (`upr`, `usync`) are unaffected
- Cons: adds a flag and one decision step the agent must take before invoking `uchange` (mitigated: most agents can decide via URL pattern + skill registry without a real HTTP call); silently picks the legacy shape when the agent forgets the flag for a fetchable issue (agent-quality issue, not framework correctness); loses the symmetry with `--branch` / `--no-branch`
- Confidence: user-provided

Alternatives:

1. Tri-state: `--fetchable` / `--no-fetchable` / error if neither when issue ref provided.
   - Pros: forces the agent to commit explicitly; mirrors `--branch` / `--no-branch`
   - Cons: more CLI surface and two extra edge-case scenarios for a property the framework does not need to enforce; `--branch` / `--no-branch` is asymmetric because it overrides a real default-branch heuristic, which has no analogue here
   - Confidence: medium
2. Default-true binary: `--no-fetchable` opt-out, fetch attempted whenever `issue_url` is provided unless the engineer opts out.
   - Pros: smallest CLI surface for the happy path (no flag needed when fetching)
   - Cons: silently triggers a network/MCP action by default, which the agent may not be configured for; moves the decision back toward the engineer
   - Confidence: low
3. Issue-URL presence alone is the trigger (no flag): `## Context` whenever `issue_url` is set.
   - Pros: simplest CLI; no flags
   - Cons: ambiguous when the agent will not actually fetch (e.g., private tracker), producing a `See [issue.md]` link that never resolves
   - Confidence: low
4. Two-phase: `uchange` always uses `## Why`+`## What` and emits a fetch attempt; on success the agent re-runs `uchange --promote-context` to rewrite the body to `## Context` and add the `See [issue.md]` link.
   - Pros: shape reflects the actual fetch outcome, not a prediction
   - Cons: multiple writers to change.md; idempotency edge cases; harder for engineers to understand; two invocations for the happy path
   - Confidence: low

## Uncertainty: where should cross-reference hub feature files live?

Decision: New `uspecs/specs/prod/softeng/cross/` subfolder reserved for navigation hubs -- zero-scenario `.feature` files whose `Feature:` description lists scenarios in their natural home features with one-line summaries and relative links. `issue-handling.feature` is the first inhabitant. Keeps the top-level softeng folder focused on action features (`uchange.feature`, `upr.feature`, etc.) and parallels the existing `shared/` convention.

- Pros: clear structural distinction between three spec-file roles in the same domain (action features at top level; reusable scenarios in `shared/`; navigation hubs in `cross/`); the folder name itself documents intent ("cross-action"); no framework changes required (the framework discovers `.feature` files recursively); future hubs (e.g., `validation.feature` aggregating validation scenarios, or `wcf-lifecycle.feature` aggregating WCF scenarios) have an obvious home
- Cons: introduces a folder for what is currently a single file (mitigated: the convention pays off as soon as the second hub is added); readers must learn the `cross/` vs `shared/` distinction (mitigated: both names are self-describing)
- Confidence: user-provided

Alternatives:

1. Keep hubs at the top level alongside action features.
   - Pros: zero new structure; one fewer folder to learn
   - Cons: mixes three different file roles (actions, hubs, ...) in one folder; readers cannot tell `issue-handling.feature` is a hub vs an action feature without opening it; the top-level listing grows linearly with every new cross-cutting concern
   - Confidence: medium
2. Co-locate hubs with `shared/` (e.g., `shared/issue-handling.feature`).
   - Pros: only one "non-action" folder; some overlap of intent (both are "supporting" files)
   - Cons: conflates two genuinely different patterns -- `shared/` files contain executable scenarios that are *included* by other features; hubs contain no scenarios and are *linked from* other features; the inclusion mechanism (`And Examples includes examples from "..."`) does not apply to hubs
   - Confidence: low
3. Use a markdown file (`cross/issue-handling.md`) instead of `.feature`.
   - Pros: avoids the "Feature with no Scenarios" awkwardness in Gherkin; native markdown link syntax
   - Cons: living-docs tooling that aggregates `.feature` files would miss the hub; mixes spec-file conventions; the `.feature` extension was explicitly chosen earlier in this CR to keep all spec files under one extension
   - Confidence: low

## Uncertainty: should the `issue.md` shape be prescribed by an artdef, or left entirely to the agent?

Decision: Add a new `artdef_issue_file.md` prescribing: H1 with the issue title; metadata as a bullet list directly under the H1 (URL, ID, State, Author, Labels, with optional Assignees/Milestone/Closed at/Linked PRs); then the issue body verbatim. If the source body does not start with a markdown heading, prepend `## Description` so the document stays well-formed; demote a leading H1 in the source body to H2 to avoid a duplicate top-level heading. `instr_uchange.md` references the artdef via `@artdef_issue_file`, so the dep scan pulls the artdef into the rendered AGENT_INSTRUCTIONS only when `--fetchable` fires the conditional.

- Pros: stable, predictable shape for `usync` contradiction reporting (known headings to anchor on); symmetric with `artdef_change_context.md` -- both are issue-handling artifacts and live next to each other in `bin/prompts/`; keeps `instr_uchange.md` short (the format prescription is data, not instruction text); single source of truth if the shape evolves (no copy-paste across actions); the wrap rule handles both structured (well-formed markdown body) and flat-prose issues without forcing the agent to invent headings
- Cons: tracker-specific fields (e.g., GitHub `assignees` vs Jira `assignee`) force the agent to map or omit; explicit metadata bullets risk inventing data when the source field is absent (mitigated: optional fields are listed as "add when available")
- Confidence: user-provided

Alternatives:

1. Minimal instruction, agent picks format.
   - Pros: smallest prompt; future-proof across exotic trackers
   - Cons: `usync` cannot anchor on stable headings; inconsistent `issue.md` shape across agents and trackers; the regression-detection story that motivated this CR is harder
   - Confidence: medium
2. Full-fidelity artdef: prescribe assignees, milestone, related issues/PRs, timestamps, reactions as required fields.
   - Pros: maximum downstream signal
   - Cons: tracker-specific fields force the agent to invent or omit, hurting consistency; brittle across trackers; bigger prompt
   - Confidence: low
3. Free-form with anchors: only require the H1 title and a final `## Source` block (URL, id); body is whatever the agent extracts.
   - Pros: zero friction across exotic trackers
   - Cons: undermines the very reason to add the artdef -- `usync` still cannot anchor on the body; metadata is buried at the bottom; H1 alone is too thin to be useful
   - Confidence: low
