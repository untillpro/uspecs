# Decisions

## Uncertainty: does the new fetchable shape support multiple issue references, or only a single issue (as today)

Decision: Single issue today (CLI surface unchanged: one `--issue-url`), and render `Refs:` as a markdown bulleted list whose single entry uses the link form `- [{issue-number}: {issue-title}](./issue-{issue-number}.md)`. Save the fetched issue under a self-identifying name `issue-{issue-number}.md` (e.g. `issue-123.md`) so future multi-issue support can add additional `issue-{N}.md` files without renaming the first one and so the filename alone identifies the issue.

- Pros: minimal CLI/parser change today; `Refs:` block uses a list shape that is uniform between the single-issue case and any future multi-issue case (no special rendering branch); self-identifying filename means a file picker / grep / archive search finds the issue by id without opening it; no positional ambiguity if issues are added out of order; link text carries human-readable identification (`{issue-number}: {issue-title}`) without forcing reviewers to open the file
- Cons: diverges from the existing `issue.md` artdef and from archived changes that used `issue.md`; requires `{issue-number}` to be reliably extractable from `--issue-url` at fetch time -- already true for GitHub URLs via `extract_issue_id`, but non-GitHub URLs (or `--issue-url` values that are not URLs) need a fallback id scheme (separate uncertainty); link text requires the issue title to be derivable when change.md is authored (available post-fetch via the H1 of the saved issue file)
- Confidence: user-provided

Alternatives:

1. Multiple issues via repeated `--issue-url`
   - Pros: matches a future multi-issue use case directly; `Refs:` block is meaningful with N > 1 entries; first-file naming could stay `issue.md` for back-compat
   - Cons: requires touching `cmd_action_uchange` arg parsing, `instr_uchange.md` fetch loop, frontmatter (`issue_url` -> list or new `issue_urls`), and `upr` `Closes #<id>` emission for multiple ids; larger surface, more tests; not needed yet
   - Confidence: medium
2. Multiple issues via comma-separated `--issue-url` value
   - Pros: single-flag CLI; uniform `issueN.md` naming
   - Cons: breaking change for consumers depending on `issue.md` as the canonical name (`usync`, archived changes); awkward for URLs containing commas; less conventional than repeated flags
   - Confidence: low

## Uncertainty: is `## How` mandatory in the fetchable shape, or still gated by the `--how` flag

Decision: Content-aware emission under `--fetchable`. When `--how` is passed, `## How` is always emitted (existing semantics). When `--how` is omitted under `--fetchable`, the agent inspects the fetched issue and emits `## How` distilled from the issue only if the issue itself describes an approach, design, or implementation direction; otherwise the section is omitted. Under non-fetchable shape, `## How` emission follows the existing `--how` flag semantics unchanged.

- Pros: respects the example (which shows `## How` present) without forcing a useless placeholder when the issue contains no approach material; preserves `--how` as an explicit override; keeps non-fetchable semantics untouched; lets fetchable change.md capture real "how" intent that the issue already carries, without manufacturing it; single source of truth (the issue) drives the optional content
- Cons: introduces a judgement call ("does the issue describe an approach?") into the agent prompt -- the criterion must be specified clearly enough that two agents on the same issue agree; emission becomes content-dependent and therefore harder to assert in tests (tests need fixtures both with and without approach material); slight risk of false positives where the agent treats incidental implementation hints as an approach
- Confidence: user-provided

Alternatives:

1. Mandatory under `--fetchable`
   - Pros: one canonical shape, no conditional branch in the artdef; matches the example unconditionally; trivial to test
   - Cons: forces a placeholder `## How` even when no approach is known; `--how` becomes a no-op under `--fetchable`
   - Confidence: high
2. Still opt-in via `--how` only (existing semantics, applied to fetchable shape too)
   - Pros: uniform flag semantics across shapes; preserves user control; no new behaviour
   - Cons: deviates from the example which shows `## How` present; requires the user to remember `--how` to get the section they likely want
   - Confidence: medium
3. Mandatory under `--fetchable`, reject `--how` as an error when combined with `--fetchable`
   - Pros: removes flag ambiguity under `--fetchable`
   - Cons: breaking for scripts that always pass `--how`; loud failure with little benefit over option 1
   - Confidence: low

## Uncertainty: behaviour when `--issue-url` does not yield an extractable issue number

Decision: Issue-number extraction under `--fetchable` is the agent's responsibility, specified in the prompt. The agent parses `--issue-url` against common issue-tracker URL conventions (GitHub `/issues/123`, GitLab `/issues/123`, Jira `BROWSE/KEY-123`, etc.), records the extracted `{issue-number}` token, and uses it to name the saved file (`issue-{issue-number}.md`) and to render the `Refs:` link text. The bash `extract_issue_id` helper is not the gate for `--fetchable`; it remains in place for the existing `upr` `Closes #<id>` plumbing on GitHub URLs.

- Pros: removes a hard CLI gate based on shell regex limits; covers GitLab, Jira, and other trackers without growing the bash helper; the agent already reads `--issue-url` to fetch and so can extract the id in the same pass; non-extractable URLs become a prompt-handled edge case (agent flags it or asks) rather than an action-level error; keeps the option open to add a frontmatter field later if `upr` needs a non-GitHub id
- Cons: extraction quality depends on the agent's prompt and reasoning rather than a deterministic regex -- two agents on the same URL might pick slightly different ids for unusual URL shapes; the prompt must enumerate enough URL shapes to avoid hallucination; `upr`'s `Closes #<id>` still relies on the bash helper, so on non-GitHub URLs the id is captured in change.md/filename but not in the PR closing keyword (no regression, just no new capability there)
- Confidence: user-provided

Alternatives:

1. Require an extractable issue number under `--fetchable`: error early if `extract_issue_id` returns empty
   - Pros: deterministic; uniform filename scheme; loud failure
   - Cons: rejects valid non-GitHub use cases until `extract_issue_id` grows; forces users to drop `--fetchable` and lose the new shape
   - Confidence: high
2. Slug fallback (`issue-{slug-from-url}.md` when no number extractable)
   - Pros: works for any URL; filename still self-identifying via slug
   - Cons: two filename schemes (numeric vs slug) in artdefs and tests; slug stability uncertain; mixes numeric and slug entries in future multi-issue
   - Confidence: medium
3. Positional name (`issue-1.md`, `issue-2.md`, ...), number used only in link text when extractable
   - Pros: deterministic regardless of URL shape
   - Cons: loses the self-identifying filename property; effectively reverts the earlier decision's rationale
   - Confidence: low

## Uncertainty: heading prefix under the fetchable shape -- `# Change:` (per the original example) or `# Change request:` (current convention)

Decision: Keep `# Change request: ...` in both fetchable and non-fetchable shapes. The `# Change:` form in the original example is treated as informal shorthand, not a rename request.

- Pros: zero divergence between fetchable and non-fetchable shapes; no churn in archived/active changes that already use `# Change request:`; downstream regexes and PR-body extractors that match the heading prefix keep working unchanged; the word "request" makes intent explicit at a glance
- Cons: contradicts the literal example the user provided; "request" is arguably noise in a folder dedicated to change requests
- Confidence: user-provided

Alternatives:

1. Rename to `# Change: ...` for the fetchable shape only
   - Pros: matches the user's example under `--fetchable`; non-fetchable archives untouched
   - Cons: two heading prefixes coexist for the same artifact kind; tools that match the heading need to accept both
   - Confidence: low
2. Rename to `# Change: ...` for both shapes
   - Pros: single consistent prefix; matches the example
   - Cons: expands scope beyond fetchable; every heading consumer (tests, PR body extraction, `usync` heuristics) must accept both prefixes during migration
   - Confidence: medium
