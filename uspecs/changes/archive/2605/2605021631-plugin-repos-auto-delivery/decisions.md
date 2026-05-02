# Decisions

## Uncertainty: how should cd.feature distinguish a development version from a stable version in `version.txt`?

Decision: Treat any SemVer pre-release suffix as dev; only bare `X.Y.Z` is stable

- Pros: works with both `2.2.0-dev` (current main) and `1.8.0-a0` (post-release output of `release.sh`); no change to `release.sh` (kept out of scope per user); aligns with the strip-on-`-` logic already in `deploy.sh`
- Cons: cd-side plugin label `-dev` no longer mirrors the source pre-release tag in `version.txt`; two slightly different conventions coexist (`-dev`/`-aN` upstream, fixed `-dev` label downstream)
- Confidence: user-provided

Alternatives:

1. Standardize on `-dev` everywhere by updating `release.sh` and `release.feature`
   - Pros: single, exact-match suffix across the project
   - Cons: requires modifying `release.sh`, which the user ruled out of scope
   - Confidence: medium
2. Make the workflow trigger the source of truth (push to main -> dev, tag `v*` -> release); drop the `version.txt` content rule
   - Pros: simplest dispatcher; immune to suffix drift
   - Cons: manual `workflow_dispatch` runs lose the dev/release signal; weakens the "version.txt drives delivery" intent in change.md
   - Confidence: medium

## Uncertainty: which GitHub authentication mechanism should `cd.yml` use to push to the per-agent plugin repos?

Decision: Fine-grained Personal Access Token owned by a maintainer, scoped to the six destination repos with `Contents: read and write`

- Pros: scope limited to exactly the six listed repos and the minimum permission needed; reduces blast radius if leaked; same single-secret operational model as a classic PAT (`USPECS_DELIVERY_TOKEN`); GitHub's recommended modern path
- Cons: fine-grained PATs have a maximum lifetime (yearly rotation required); tied to one maintainer's account (bus factor)
- Confidence: high

Alternatives:

1. Classic PAT with `repo` scope
   - Pros: simplest; no per-repo wiring
   - Cons: `repo` scope grants write to every private repo the maintainer can access, far beyond the six destinations
   - Confidence: medium
2. GitHub App installed on the `uspecs` org with `Contents: write`
   - Pros: scoped to exactly the six repos; not tied to any individual; short-lived installation tokens
   - Cons: more setup (app + private key + token-minting step in the workflow)
   - Confidence: high
3. Per-repo deploy keys
   - Pros: narrowest possible scope (one key per repo)
   - Cons: six secrets to manage and rotate; matrix must select the right key per agent
   - Confidence: low

## Uncertainty: where should the cd-only `templates/` directory live in the repo?

Decision: `scripts/templates/`

- Pros: keeps repo top-level lean (no new root-level directory); co-located with `scripts/_lib/gen-uspecs-market.py` so the templates sit next to their only consumer; clearer scope than a generic `/templates/` at the root
- Cons: slightly less discoverable than a top-level directory; `gen-uspecs-market.py` must still resolve relative to repo root (or to its own `scripts/_lib/../templates`)
- Confidence: user-provided

Alternatives:

1. `scripts/_lib/templates/` (one level deeper, fully co-located with the script)
   - Pros: simplest path resolution (`Path(__file__).parent / "templates"`)
   - Cons: buries data assets under `_lib/` which conventionally holds code helpers
   - Confidence: high
2. `/templates/` at repo root (original change.md proposal)
   - Pros: visually prominent; matches the implementation example layout
   - Cons: pollutes top-level with a directory used only by one feature; vague name invites unrelated content
   - Confidence: medium
3. `.github/cd-templates/`
   - Pros: clearly scoped to CI/CD assets
   - Cons: `.github/` is conventionally for GitHub-platform metadata, not arbitrary script inputs
   - Confidence: low
4. `uspecs/specs/devops/cd/templates/`
   - Pros: keeps cd assets together with the cd spec
   - Cons: mixes runtime template content with specs; specs become a runtime data dependency
   - Confidence: low

## Uncertainty: what is the canonical name and path of the entry-point script - `scripts/deliver.sh` or `scripts/deploy.sh`?

Decision: `scripts/deliver.sh` (the provided `deploy.sh` example is renamed on adoption)

- Pros: matches the feature name "Continuous Delivery" and the `cd.feature`/`cd.yml` artifacts; aligns with the existing `release` -> `release.sh` naming pattern under `scripts/`; "deliver" precisely describes pushing artifacts to another repo without running them
- Cons: one-off rename of the reference file when adopted
- Confidence: high

Alternatives:

1. `scripts/deploy.sh`
   - Pros: zero-change to the provided implementation example
   - Cons: contradicts the "Continuous Delivery" naming and `cd.*` artifacts; "deploy" implies running the artifact rather than delivering it
   - Confidence: medium
2. `scripts/cd.sh`
   - Pros: tightest naming consistency with `cd.feature` and `cd.yml`
   - Cons: very short/opaque in `scripts/`; diverges from the `release.sh` precedent
   - Confidence: low

## Uncertainty: which workflow triggers should `cd.yml` use?

Decision: `push` on `main`, `push` on tags `v*`, plus `workflow_dispatch`

- Pros: dev stream auto-delivered on every `main` push; stable stream auto-delivered on each `vX.Y.Z` tag (the only ref where `release.sh` writes a stable `version.txt`); manual dispatch covers re-runs after transient failures and one-off republishes without a new commit
- Cons: operators must understand that dispatch routing still follows the chosen ref's `version.txt` (dev vs release)
- Confidence: user-provided

Alternatives:

1. `push: main` and `push: tags v*` only (no manual dispatch; original change.md)
   - Pros: minimal surface; every delivery traces to a push event
   - Cons: re-running after a transient failure requires re-running the existing workflow run rather than a clean dispatch
   - Confidence: medium
2. `push: main` only, plus `workflow_dispatch` (drop tag trigger)
   - Pros: simplest event set
   - Cons: stable releases never auto-deliver because `release.sh` keeps the stable `version.txt` only on the tag, not on `main`; "Continuous Delivery" weakened to dev-only
   - Confidence: low
3. `push: main` (paths-filtered), `push: tags v*`, plus `workflow_dispatch`
   - Pros: avoids dev commits for changes that cannot affect plugin output
   - Cons: contradicts the "every `main` SHA produces a new dev commit" intent; whitelist is hard to keep correct
   - Confidence: low

## Uncertainty: which context should `cd.feature` belong to — existing `dev` or a new `cd` context?

Decision: `dev` context — `uspecs/specs/devops/dev/cd.feature`

- Pros: no new context needed; `dev` already covers release automation and GitHub CI/CD; keeps the domain slim; consistent with `release.feature` living in `dev`
- Cons: `dev` context grows broader; "delivery to external repos" is more ops-facing than "dev tooling"
- Confidence: high

Alternatives:

1. New `cd` context — `uspecs/specs/devops/cd/cd.feature`
   - Pros: clean separation of concerns; CD is a distinct pipeline concern from developer tooling; easier to extend
   - Cons: single-feature context adds overhead; inconsistent with `release.feature` which also does automated delivery yet lives in `dev`
   - Confidence: medium

## Uncertainty: who chooses the destination repo (Dev vs Release) - the workflow or `deliver.sh`?

Decision: Workflow dispatches; `deliver.sh` operates on a pre-resolved repo

- Pros: matches the existing `deploy.sh` example contract (single `--marketplace-repo`, optional `--release`); clear separation - workflow does ref/version inspection + URL mapping + clone, script does generation + commit + push; `deliver.sh` stays easy to test locally against any chosen path
- Cons: dispatch logic (suffix detection + URL mapping) lives in YAML, less unit-testable than bash; the URL list and `version.txt` inspection are duplicated if any other caller of `deliver.sh` ever needs the same dispatch
- Confidence: high

Alternatives:

1. `deliver.sh` dispatches; workflow only passes the agent
   - Pros: dispatch logic centralized in one bash script (testable, reusable from a maintainer's laptop)
   - Cons: extends the example `deploy.sh` contract; script embeds destination URLs and performs token-authenticated clones
   - Confidence: high
2. Hybrid: workflow passes both URLs, `deliver.sh` picks
   - Pros: URL list in YAML; dispatch logic in bash
   - Cons: awkward CLI surface; clone still has to happen somewhere
   - Confidence: low
