# Decisions: Three-branch release cycle (dev, rc, release)

## Uncertainty: Branch topology and protection

Decision: Three long-lived rolling branches (`main`, `rc`, `release`); `rc` and `release` are force-pushed when promoted; tags `vX.Y.Z` preserve history across recreations; branch protection rules are out of scope of this change.

- Pros: simplest model that fits a single product (no per-minor proliferation); one branch to track per stream; force-push is the natural primitive for "(re)create from upstream"
- Cons: non-linear history on `rc`/`release` across cycles; deferring branch protection means workflow identity must be trusted to force-push
- Confidence: user-provided

Alternatives:

1. Per-minor long-lived branches (`release/2.3`, `release/2.4`, ...) with cherry-pick patch flow (Kubernetes-style)
   - Pros: supports long-term maintenance of older minors; no force-push required
   - Cons: branch proliferation; tooling needs to know "current minor"; consumers must follow renamed branches
   - Confidence: medium
2. Single rolling `release` plus protected branches with workflow bypass (Rust-style with branch protection)
   - Pros: protects against accidental developer force-push while preserving rolling model
   - Cons: extra GitHub config; out of scope for this change
   - Confidence: medium

## Uncertainty: Version transition mechanics for "Create a new rc" -- where the minor bump falls and what version ends up on each branch

Decision: Branch first, then bump main (rc carries the version being stabilized as `X.Y.0-rc`; main bumps to `X.Y+1.0-dev`)

- Pros: matches today's mental model where `version.txt` on main is the next planned release; rc clearly represents the in-flight version
- Cons: workflow does two writes (rc, then main) and two pushes
- Confidence: user-provided

Alternatives:

1. Bump main first, then branch rc from new main
   - Pros: literal reading of original bullet order
   - Cons: rc and main both target the new minor; what was being developed as `X.Y.0-dev` is silently relabeled
   - Confidence: low
2. No minor bump on main; rc just renames suffix; main keeps tracking same version
   - Pros: simplest workflow; bump deferred to "Create release"
   - Cons: feature work landing on main during stabilization carries a misleading frozen-on-rc version
   - Confidence: medium

## Uncertainty: Guard for "Create a new rc" when an unpromoted `rc` already exists

Decision: Workflow aborts if `rc` exists and has commits not present on `release` (first rc is allowed when `release` does not exist); branch-off commit is pinned to "main HEAD at workflow trigger time"

- Pros: protects rc-only fixes (e.g., back-ports cherry-picked to rc) from being silently force-pushed away; explicit trigger commit removes ambiguity
- Cons: starting a new rc cycle requires promoting or abandoning the previous rc first; bootstrap exception needed for the first rc
- Confidence: high

Alternatives:

1. Always force-recreate (no guard)
   - Pros: simplest; matches naive "(re)created" reading
   - Cons: silently destroys unmerged rc fixes
   - Confidence: low
2. Require an explicit `--force` workflow input to allow recreation when rc has unpromoted commits
   - Pros: same protection with an escape hatch
   - Cons: extra workflow input; "force" is easy to abuse
   - Confidence: medium

## Uncertainty: What rc/version.txt represents during a release line -- next-minor vs next-patch tracker

Decision: rc/version.txt is an anticipatory next-patch tracker; after each release/patch event the workflow bumps rc by one patch (`2.3.0-rc` -> `2.3.1-rc` after initial release; `2.3.1-rc` -> `2.3.2-rc` after "Initiate patch" of `2.3.1`); rc is force-pushed back to `X.Y+1.0-rc` only when a new rc is cut.

- Pros: rc/version.txt always names "the next thing that will ship", so "Initiate patch" computes the patch number by simply stripping `-rc`; one source of truth for next version; aligns with the `-rc` semantics used by patch branches
- Cons: between patches, rc CD would publish builds whose content matches the just-shipped release but whose version label anticipates the next patch -- mitigated by the rc CD filter (see below); two extra workflow-authored commits per cycle
- Confidence: user-provided

Alternatives:

1. Next-minor tracker: rc stays at `X.Y.0-rc` for the whole cycle; "Initiate patch" computes the patch number from `release/version.txt + 1`
   - Pros: matches widespread `-rc = preview of next minor` semantics; fewer workflow commits on rc
   - Cons: rc and patch branch carry different versions; patch number lives in workflow logic, not in a file
   - Confidence: medium
2. No anticipatory bump at all; rc/version.txt stays at `2.3.0-rc` until next "Create rc"; patch number derived from `release/version.txt + 1`
   - Pros: simplest; no workflow-authored bumps on rc
   - Cons: rc/version.txt no longer expresses what the next thing will be
   - Confidence: medium

## Uncertainty: Guards for "Create an initial release"

Decision: Workflow aborts if any `patch-X.Y.*` branch exists OR if rc/version.txt has a non-zero patch component

- Pros: the patch-branch guard prevents silently orphaning in-flight patches when release is force-pushed; the non-zero-patch guard catches misuse of the workflow against a release-line rc (where rc has already advanced to `X.Y.N-rc` and "initial release" is no longer the right operation)
- Cons: starting a new minor requires resolving or deleting in-flight patches first; the non-zero-patch guard requires the rc anticipatory bump decision above to be in effect
- Confidence: user-provided

Alternatives:

1. Patch-branch guard only; allow non-zero-patch rc
   - Pros: fewer abort conditions
   - Cons: lets the workflow run against a rc that has already begun its patch line; semantically wrong
   - Confidence: low
2. No guards; always force-recreate
   - Pros: simplest
   - Cons: silently orphans in-flight patches; allows confusing operations
   - Confidence: low

## Uncertainty: Patch branch base, version mechanics, and concurrency

Decision: `patch-X.Y.Z` is created from `rc` HEAD when `rc.major.minor == release.major.minor`, otherwise from `release` HEAD; a single workflow-authored commit "version X.Y.Z" sets `version.txt` to the patch number (strips `-rc` from `rc/version.txt` in the same-line case); only one patch in flight (workflow aborts if `patch-X.Y.Z` already exists, or if `release` does not exist); patch number is `release/version.txt` patch component + 1 (equal to stripping `-rc` from `rc/version.txt` when on the same release line, by the rc anticipatory-bump invariant)

- Pros: when rc and release share a major.minor, the fix already cherry-picked onto rc carries through to the patch branch with its original commit hash (no second cherry-pick); when rc has moved to a new minor, branching from release keeps unrelated rc work out of the patch; single-patch-in-flight matches the linear feel of the rest of the flow; patch number rule is uniform across both paths
- Cons: `patch.sh` has two code paths and must compare rc and release versions to choose the source; in the same-line case, rc-only commits accumulated since promotion land on the patch branch (mitigated by squash-merge to release); blocks unrelated parallel patches
- Confidence: user-provided

Alternatives:

1. Always branch from `release` HEAD; developer cherry-picks the fix from `rc` onto the patch branch
   - Pros: single rule; predictable merge base equal to release HEAD; no rc-only history bleeding into the patch
   - Cons: requires a manual cherry-pick even when rc already has exactly the desired fix; loses the original commit hash for the fix
   - Confidence: medium
2. Always branch from `rc` HEAD (no fallback)
   - Pros: simplest when the same-line case is dominant; no cherry-pick step
   - Cons: breaks once rc advances to a new minor while an old release still needs a patch
   - Confidence: low
3. Workflow input chooses the base (`--from rc|release`)
   - Pros: explicit; no implicit rule to remember
   - Cons: extra knob to misuse; non-deterministic outcome from the same trigger
   - Confidence: low
4. Highest existing `patch-X.Y.*` + 1; multiple patches allowed
   - Pros: supports parallel hotfixes
   - Cons: merge order matters; tag/version assignment no longer 1:1 with branch name
   - Confidence: low

## Uncertainty: "Create patch" merge mechanics -- tag creator and patch branch cleanup

Decision: Developer accepts the PR from `patch` to `release`; merge triggers a workflow that (re)creates lightweight tag `vX.Y.Z` on the new release HEAD (dropping the tag if it exists) and deletes `patch`

- Pros: tag automation matches "Create initial release"; deletion frees the one-patch-in-flight slot automatically; (re)create-if-exists semantics align with the rolling-branch convention; lightweight tag style matches the existing `release.sh`
- Cons: merge mode (squash vs merge commit vs rebase) is left to the PR settings; tag is lightweight (no annotation message)
- Confidence: high

Alternatives:

1. Annotated tag with explicit "release X.Y.Z" message
   - Pros: tag carries metadata
   - Cons: diverges from existing tooling; another decision to maintain
   - Confidence: medium
2. Manual tagging by the developer after merge
   - Pros: no extra workflow
   - Cons: easy to forget; inconsistent timing; loses parity with "Create initial release"
   - Confidence: low
3. Refuse to (re)create existing tags
   - Pros: tag immutability
   - Cons: blocks recovery if the tag was placed on a wrong commit; conflicts with "Create initial release" tag-recreation semantics
   - Confidence: low

## Uncertainty: "Create an initial release" tag mechanics and retry semantics

Decision: Annotated tag `vX.Y.0` with create-if-not-exists semantics (immutable); workflow body is idempotent (each state-changing step is a no-op when its post-condition already holds); abort guards run before any mutation; an optional `force` input bypasses per-step skips but not the abort guards or tag immutability

- Pros: tag carries metadata (author, date, "release X.Y.0" message) and aligns with industry practice for release tags (SemVer, GitHub Immutable Releases); immutability preserves the "tags pin historical points" guarantee already established for the rolling-release model; idempotent steps make partial-failure recovery a simple rerun rather than a manual cleanup; explicit `force` input is the single audited override surface
- Cons: tag mechanics now diverge from the existing "Create patch" decision (lightweight + (re)create-if-exists) until that decision is revisited; recovering from a wrongly-tagged commit requires deliberate manual `git tag -d` plus push, by design
- Confidence: user-provided

Alternatives:

1. Lightweight tag, force-recreate on every run (the original draft)
   - Pros: simplest mutation; no metadata to fill
   - Cons: a partial-failure rerun re-force-pushes `release` and silently moves the tag; weakens the "tags preserve historical points" property; no metadata
   - Confidence: low
2. Annotated tag, force-recreate on every run
   - Pros: metadata; matches naive "always set the tag to current state" reading
   - Cons: same immutability-violation problem as (1)
   - Confidence: low
3. Lightweight tag, create-if-not-exists, idempotent steps
   - Pros: idempotent + immutable without metadata commitment
   - Cons: misses the metadata benefit while paying the same wording cost; inconsistent with industry practice for release tags
   - Confidence: medium
4. No idempotency (single-shot workflow); operator manually cleans up after partial failures
   - Pros: simplest workflow logic
   - Cons: every partial failure requires a custom recovery procedure; high operator burden; error-prone
   - Confidence: low

## Uncertainty: "Validate patch" check semantics

Decision: `validate_patch` workflow fails if `patch/version.txt` is not exactly `release/version.txt` with the patch component incremented by 1 (same major and minor, `patch.patch == release.patch + 1`)

- Pros: catches both the cross-line mistake (e.g., a stale `patch` left over from `2.3.x` PR'd while release is now `2.4.0`) and the wrong-patch-number mistake (e.g., patch claiming `2.3.5` while release is `2.3.0`); ensures monotonic patch numbering; aligns with the one-patch-in-flight invariant
- Cons: requires semver parsing in the workflow; assumes patches are issued strictly sequentially (which the rest of the spec already enforces)
- Confidence: user-provided

Alternatives:

1. Same release line only: require `patch.major == release.major` and `patch.minor == release.minor`; ignore patch component
   - Pros: trivial string-prefix compare; catches the cross-line mistake
   - Cons: misses wrong-patch-number mistakes (e.g., skipped numbers)
   - Confidence: medium
2. Strict equality (`patch == release` exactly): implies the check runs after the merge
   - Pros: post-merge sanity check
   - Cons: contradicts "triggered on PR creation"; no longer a gate; less useful
   - Confidence: low
3. Composite rule that also cross-checks rc/version.txt to identify which initiation path was used
   - Pros: most defensive
   - Cons: complex; partly redundant with invariants "Initiate patch" already enforces
   - Confidence: medium

## Uncertainty: What happens to the `release` branch and its tags when the next minor is released

Decision: Single rolling `release` branch; force-recreated each new minor; tags preserve historical points

- Pros: one branch to track for "latest stable"; tags allow installing any older version
- Cons: linear history on release is lost across minors
- Confidence: user-provided

Alternatives:

1. Per-minor release branches (`release/2.3`, `release/2.4`); no rolling release
   - Pros: clean separation; supports long-term maintenance of older minors
   - Cons: more branches; CD needs to know "current"; consumers must update branch names
   - Confidence: medium
2. Per-minor release branches plus a rolling release alias to the latest
   - Pros: combines old-minor preservation with a single "latest" pointer
   - Cons: most moving parts; alias maintenance is an extra step
   - Confidence: medium

## Uncertainty: Back-porting fixes across `main`, `rc`, and patch branches

Decision: Developer-driven; no workflow automation. Recommended order: fix on `main` -> cherry-pick to `rc` -> initiate patch and cherry-pick from `rc` to the patch branch (skip steps that do not apply)

- Pros: zero new automation; flexible (skip when not applicable); puts the fix on the longest-lived line first so cherry-picks flow downstream
- Cons: relies on human discipline; easy to miss; no enforcement
- Confidence: user-provided

Alternatives:

1. Automated back-port PRs from release to rc and main after "Create patch"
   - Pros: nothing forgotten by default; surfaces conflicts as PRs
   - Cons: extra workflow; cherry-pick conflicts on diverged branches need manual fix-up
   - Confidence: high
2. Auto-merge release -> rc -> main after each patch
   - Pros: keeps lines fully aligned
   - Cons: pulls release-only commits into pre-release lines; conflict-prone; mixes histories the model deliberately separates
   - Confidence: low

## Uncertainty: rc CD interaction with the workflow-authored anticipatory bumps

Decision: rc CD skips commits whose subject starts with `version` and whose resulting `version.txt` has patch > 0; main and release CD are unaffected

- Pros: suppresses misleading rc builds whose content is byte-identical to the just-shipped release (the `version 2.3.1-rc`, `version 2.3.2-rc`, ... bump commits) while still publishing previews for developer cherry-picks at the same version; the initial `version 2.3.0-rc` build still fires (patch = 0) so the first rc preview is published; rule keys on the existing commit-message convention used by all version-bump scripts
- Cons: requires both conditions to be checked; relies on workflow-authored commits keeping the `version ...` subject discipline
- Confidence: user-provided

Alternatives:

1. Filter by commit author (skip commits authored by the workflow bot)
   - Pros: doesn't depend on subject formatting
   - Cons: future automation that legitimately authors content commits would be filtered; weaker tie to intent
   - Confidence: medium
2. Filter by diff (skip commits whose diff modifies only `version.txt` and patch > 0)
   - Pros: doesn't depend on subject formatting either
   - Cons: requires diff inspection in CD; edge case if a real fix happens to touch only `version.txt`
   - Confidence: medium
3. No filter; accept the redundant builds
   - Pros: simplest CD logic
   - Cons: rc plugin repository churns with builds whose content equals release
   - Confidence: low

## Uncertainty: Plugin repository cardinality for CD

Decision: Per-stream-per-agent: 3 streams x 3 agents = 9 plugin repositories; `cd.yml` matrix gains a `stream` dimension alongside the existing `agent` dimension; each combination has its own destination repo and delivery token

- Pros: cleanest separation; consumers install a stable repo by name (e.g., `uspecs-claude` vs `uspecs-claude-rc` vs `uspecs-claude-dev`); aligns with how `is_dev_version` already differentiates banner/name
- Cons: 6 new repos to provision and grant tokens for; secrets/config scale linearly
- Confidence: user-provided

Alternatives:

1. Per-stream-only (3 repos); agents folded into a single repo per stream
   - Pros: only 3 destination repos
   - Cons: collapses existing per-agent structure consumers already use
   - Confidence: low
2. Per-agent-only (3 repos); stream encoded in version string; consumers select by version constraint
   - Pros: zero new repositories
   - Cons: a single repo holds all three streams; consumers need version-constraint discipline
   - Confidence: medium
3. Per-stream-per-agent for Dev and Release (6 repos), RC folded into Dev
   - Pros: fewer repos
   - Cons: contradicts the explicit RC stream
   - Confidence: low

## Uncertainty: Replacement strategy for existing `scripts/release.sh` and `.github/workflows/release.yml`

Decision: Rewrite `release.sh` and `release.yml` in place for the new "Create an initial release" flow; add `rc.sh`/`rc.yml` and `patch.sh`/`patch.yml` as new files; add one merge-triggered auto-workflow that finalizes "Create patch" (tag and patch-branch deletion); one workflow per action (no parameterized super-workflow)

- Pros: name continuity (`release.*` keeps meaning "produce a release"); each workflow is small and focused; matches the explicit "Developer runs `rc`/`release`/`patch` github workflow" scenarios
- Cons: history of the old `release.sh` semantics is lost in the diff; four workflow files to maintain instead of one
- Confidence: high

Alternatives:

1. Keep old `release.sh` as a deprecated stub; add new scripts under different names
   - Pros: old behavior remains discoverable
   - Cons: dead code; ambiguity about which to invoke
   - Confidence: low
2. Single parameterized workflow `release-cycle.yml` with an `action` input (`rc | release | patch`)
   - Pros: one file
   - Cons: branching logic in YAML; harder to read than small workflows
   - Confidence: medium

## Uncertainty: Marketplace and plugin name pattern for the rc stream

Decision: Mirror the existing dev pattern -- non-release streams insert a `{stream}-` segment after `uspecs-` in the marketplace name and use `uspecs-{stream}` as the plugin id. Concretely:

- release: market `uspecs-plugins-{agent}`, plugin `uspecs`
- dev:     market `uspecs-dev-plugins-{agent}`, plugin `uspecs-dev`
- rc:      market `uspecs-rc-plugins-{agent}`, plugin `uspecs-rc`

`resolve_names`/`dev_market_name` in `scripts/_lib/gen-uspecs-market.py` is generalized to a stream-aware helper (e.g., `nonrelease_market_name(stream)`) that uses the same rule for both `dev` and `rc`; release keeps the unsuffixed form.

- Pros: single rule for all non-release streams; no migration of existing dev or release names; minimal diff in `gen-uspecs-market.py`; README banner logic extends naturally to a third variant; matches the example naming hinted at in earlier decisions
- Cons: three coexisting top-level marketplace name prefixes (`uspecs-plugins-*`, `uspecs-dev-plugins-*`, `uspecs-rc-plugins-*`); 6 new repositories must still be provisioned with delivery tokens
- Confidence: user-provided

Alternatives:

1. Suffix after agent: `uspecs-plugins-{agent}-rc` / `...-dev`, plugin `uspecs-rc` / `uspecs-dev`
   - Pros: groups all marketplaces under a single `uspecs-plugins-*` prefix
   - Cons: breaks existing `uspecs-dev-plugins-{agent}` consumers; requires migration
   - Confidence: low
2. Stream as plugin-id only; one marketplace per agent hosting all three streams
   - Pros: 3 destination repos instead of 9
   - Cons: contradicts the already-decided "Per-stream-per-agent: 9 plugin repositories" topology
   - Confidence: low
3. Asymmetric: keep dev/release as today, introduce only `uspecs-plugins-{agent}-rc` for rc
   - Pros: no migration of dev or release names
   - Cons: two different conventions for non-release streams; extra special case in `resolve_names`
   - Confidence: low

## Uncertainty: One-time migration from the current single-track flow to the three-branch model

Decision: Lazy bootstrap. Ship the new workflows without creating `rc` or `release` ahead of time; the first run of `rc.yml` materializes `rc`, the first run of `release.yml` materializes `release`. The rc-workflow guard "abort if `rc` has unpromoted commits not on `release`" is qualified to allow the first rc when `rc` does not yet exist (the bootstrap exception already noted under "Guard for Create a new rc"). Existing pre-cutover tags `vX.Y.Z` are left in place; the new flow produces tags from the next minor onward. CD jobs for `rc` and `release` are no-ops while the source branch is absent (the matrix entry is skipped when the branch ref does not exist).

- Pros: no one-time bootstrap script to write or test; cutover is just merging the workflow PR; old tags remain reachable; reverting the workflow PR restores the old single-track behavior; reuses the steady-state `rc.yml`/`release.yml` primitives for the first cycle (no special-case code path)
- Cons: between merge of this change and the first `rc.yml` run, the rc and release matrix entries in `cd.yml` produce nothing -- requires CD to detect and skip absent source branches; the 6 new plugin repositories must still be provisioned as a separate manual prerequisite, but they can sit empty until the first cycle
- Confidence: user-provided

Alternatives:

1. Eager bootstrap as part of the change PR: a one-time `scripts/bootstrap-streams.sh` creates `rc` from `main` with `X.Y.0-rc`, then `release` from `rc` with `X.Y.0` plus tag `vX.Y.0`, and bumps `main` to `X.Y+1.0-dev`
   - Pros: all three streams populated on day one; first patch issuable immediately
   - Cons: duplicates steady-state workflow logic for a single use; tags a commit that was never validated as a release; couples PR with destination-repo provisioning
   - Confidence: low
2. Eager bootstrap of branches only, no synthetic release tag: `rc` is seeded from `main`; `release` is left empty until the first real release
   - Pros: avoids fabricating a release tag; rc CD active immediately
   - Cons: mostly equivalent to lazy bootstrap with one extra script; release CD still idle until first release
   - Confidence: low
3. Phased rollout in two PRs: ship `rc.yml`/`patch.yml` first, replace `release.yml` and add the CD `stream` dimension in a follow-up
   - Pros: smaller blast radius per PR
   - Cons: temporary state where the old `release.yml` tags `main` while a new `rc` exists; contradicts the already-decided "rewrite `release.sh` and `release.yml` in place"
   - Confidence: low
