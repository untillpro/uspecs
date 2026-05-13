---
registered_at: 2026-05-09T10:49:58Z
change_id: 2605091049-release-cycle-dev-rc-branches
baseline: 00cd47a0951be732691d6b8dea7fef4f7860035c
---

# Change request: Four-branch release cycle (dev, rc, rc-maint, release)

## Why

The current single-track release flow tags directly off `main` and immediately bumps it to the next `-dev` version, leaving no stabilization window between active development and a tagged release. A separate release candidate stage is needed so changes can be frozen, validated, and patched without blocking ongoing development on `main`.

## What

### Release feature

Four long-lived rolling branches: `main` (dev stream), `rc` (release candidate stream for the next minor), `rc-maint` (rc-style maintenance stream for the currently-released minor; patch source when `rc` has already moved to a newer minor), `release` (release stream). `rc`, `rc-maint`, and `release` are force-pushed when promoted; tags `vX.Y.Z` preserve historical points across recreations. Branch protection is out of scope of this change.

- Create rc
  - Basic flow
    - Background
      - version.txt in the `main` branch contains `2.3.0-dev`
      - last commit in `main` is not a version bump
      - CHANGELOG.md is prepared and contains
    - Developer runs `rc` github workflow
    - If `rc` branch does not exist it is created from `main`
    - Current `rc` HEAD is printed as a message "Current rc HEAD is {hash} ({message})"
    - Current `rc/version.txt` is printed as a message "Current rc version is {version}"
    - rc is force-pushed from `main` HEAD
    - if `rc/version.txt` != `2.3.0-rc`:
      - `version.txt` updated to `2.3.0-rc`
      - commit "chore: version 2.3.0-rc" on `rc`
    - if `main/version.txt` == `2.3.0-dev`
      - `version.txt` updated to `2.3.1-dev`
      - commit "chore: version 2.4.0-dev"
  - Exceptional flow
    - If last commit in the main is `chore: version*` workflow aborts with message "Last commit is a version bump; please add commits on top of the version bump to trigger the rc workflow"

- Create release
  - Background
    - version.txt in the `rc` branch contains `2.3.0-rc` (zero patch)
    - No `patch-X.Y.*` branches exist
  - Developer runs `release` github workflow
  - Basic flow
    - if `release` does not exist it is created from `rc`
    - if `release/version.txt` != `2.3.0`: commit "version 2.3.0" on `release` (`version.txt` updated to `2.3.0`)
    - if tag `v2.3.0` does not exist: create annotated tag `v2.3.0` on `release` HEAD with message "release 2.3.0"
  - Note: tag `v2.3.0` is immutable once created; on subsequent minors the existing release branch is force-pushed forward and a new immutable `vX.Y.0` tag is created, while older `vX.Y.Z` tags remain pinned to their original commits

- Initiate patch for rc/release
  - Background
    - `target` version.txt contains version core `2.3.2`
  - Developer runs `patch` github workflow
    - `target`: `rc` or `release`
    - `hashes`: optional, comma-separated list of specific commits to cherry-pick to the patch branch (if empty, no cherry-picks are attempted and the patch branch is created directly from the target)
  - Basic flow
    - if `patch-2.3.3-{target}` does not exist: create it from `target` HEAD
    - if `patch-2.3.3-{target}/version.txt` version core == `2.3.2`: bump it to `2.3.3`, commit "version 2.3.3-{target}"
    - if hashes is specified and not cherry-picked to `patch-2.3.3-{target}`: 
      - Attempt to cherry-pick the specified commits is made
      - Error is not critical and logged
      - Using `git cherry`
    - if `{target}/version.txt` version core == `2.3.2`: bump to `2.3.3` with commit "version 2.3.3-{target}"
    - If pull request
  - Exeptional flow
    - If patch is greater than zero and previous patch branch exists (`patch-2.3.1-{target}`) then workflow aborts with error "Previous patch branch patch-2.3.1-{target} exists; please resolve the patch before initiating a new one"

- Backport a fix
  - Developer's responsibility; no workflow automation
  - Recommended order when `rc.major.minor` == `release.major.minor`: fix on `main` -> cherry-pick to `rc` -> initiate patch and cherry-pick from `rc` to the patch branch (skip steps that do not apply)
  - Recommended order when `rc.major.minor` != `release.major.minor`: fix on `main` -> cherry-pick to `rc-maint` -> initiate patch and cherry-pick from `rc-maint` to the patch branch (cherry-pick to `rc` as well if the fix also applies to the next minor)

### Continuous Delivery feature

- External actor pushes a commit to `main`, `rc`, or `release` branches
  - Note: patch branches do not trigger CD
  - Note: rc CD skips commits whose subject starts with `version` and whose resulting `version.txt` has patch > 0 (suppresses the workflow-authored anticipatory bumps `version 2.3.1-rc`, `version 2.3.2-rc`, ...; the initial `version 2.3.0-rc` and developer cherry-picks still fire CD)
- Version is delivered to Dev, RC, or Release Plugin Repositories based on version format
  - For main branch plugin repository has version like: `2.3.0-dev+20260504-1923.0c90696cf94f`
  - For rc branch plugin repository has version like: `2.3.0-rc+20260504-1923.0c90696cf94f`
  - For release branch plugin repository has version like: `2.3.0`
- One plugin repository per stream per agent (3 streams x 3 agents = 9 repositories); `cd.yml` matrix gains a `stream` dimension alongside the existing `agent` dimension; each combination has its own destination repo and delivery token
  - Marketplace names follow the existing dev pattern: release `uspecs-plugins-{agent}`, dev `uspecs-dev-plugins-{agent}`, rc `uspecs-rc-plugins-{agent}`; plugin ids are `uspecs`, `uspecs-dev`, `uspecs-rc`

### References

- [version.txt](../../../version.txt)
- [scripts/release.sh](../../../scripts/release.sh)
- [scripts/deliver.sh](../../../scripts/deliver.sh)
- [scripts/_lib/gen-uspecs-market.py](../../../scripts/_lib/gen-uspecs-market.py)
- [.github/workflows/release.yml](../../../.github/workflows/release.yml)
- [.github/workflows/cd.yml](../../../.github/workflows/cd.yml)
- [uspecs/specs/devops/dev/release.feature](../../../uspecs/specs/devops/dev/release.feature)
- [uspecs/specs/devops/dev/release--td.md](../../../uspecs/specs/devops/dev/release--td.md)
- [uspecs/specs/devops/dev/cd--td.md](../../../uspecs/specs/devops/dev/cd--td.md)

## How

## Domain specifications

- [x] update: [devops/domain.md](../../specs/devops/domain.md)
  - update: "RC Plugin Repository" concept - source branch is `rc` (not `main`); updated automatically on push to `rc` while `version.txt` carries a `-rc` suffix
  - update: "Release Plugin Repository" concept - updated automatically on push to the `release` branch (when `version.txt` carries no pre-release suffix), with `vX.Y.Z` tag (re)created on that commit

## Functional design

- [x] update: [devops/dev/release.feature](../../specs/devops/dev/release.feature)
  - remove: existing "Developer triggers release via GitHub Action" scenario (single-track flow no longer applies)
  - add: scenario "Create a new rc" - `rc` force-pushed from `main` HEAD; `rc/version.txt` set to `X.Y.0-rc`; `main` bumped to `X.Y+1.0-dev`
  - add: scenario "Create an initial release" - idempotent steps: force-push `release` from `rc` (skipped if `release/version.txt` already at `X.Y.0`); annotated tag `vX.Y.0` created if absent; `rc/version.txt` bumped to `X.Y.1-rc` (skipped if already bumped)
  - add: scenario "Create initial release aborts" - aborts when any `patch-X.Y.*` exists, when `rc/version.txt` has non-zero patch, or when tag `vX.Y.0` exists on a commit other than the prospective `release` HEAD
  - add: scenario "Create initial release is idempotent on retry" - rerun after partial failure converges to the target state without re-force-pushing or recreating the tag
  - add: scenario "Initiate patch from rc (same major.minor)" - `patch-X.Y.Z` branched from `rc`; `patch/version.txt` set to `X.Y.Z`; `rc` bumped to `X.Y.Z+1-rc`
  - add: scenario "Initiate patch from rc-maint (different major.minor)" - `patch-X.Y.Z` branched from `rc-maint` HEAD; `patch/version.txt` set to `X.Y.Z`; `rc-maint` bumped to `X.Y.Z+1-rc`; `rc` unchanged
  - add: scenario "Create patch" - PR from `patch-X.Y.Z` to `release` merged; tag `vX.Y.Z` (re)created on the new `release` HEAD; `patch-X.Y.Z` branch deleted
  - add: scenario "Validate patch" - `validate_patch` runs on PR creation and fails unless `patch.major == release.major`, `patch.minor == release.minor`, and `patch.patch == release.patch + 1`

- [x] update: [devops/dev/cd.feature](../../specs/devops/dev/cd.feature)
  - add: routing for rc-suffixed `version.txt` - routes to RC Plugin Repositories `uspecs-rc-plugins-{agent}`; plugin version `<core>-rc+<TS>.<SHORT_SHA>`
  - add: scenario "Push to rc delivers rc stream"
  - add: scenario "Push to release delivers release stream"
  - add: rule "rc CD skips anticipatory bumps" - rc CD skips commits whose subject starts with `version` AND whose resulting `version.txt` has patch > 0; initial `version X.Y.0-rc` and developer cherry-picks still fire CD
  - add: scenario "Patch branches do not trigger CD"
  - update: existing "Tag v* delivers release stream" scenario - align with the push-to-`release` branch trigger model (tag is created on the same commit that is pushed to `release`)

## Provisioning and configuration

- [x] create: 3 RC Plugin Repositories under the `uspecs` GitHub org (USER ACTION REQUIRED)
  - `uspecs/uspecs-rc-plugins-claude`
  - `uspecs/uspecs-rc-plugins-augment`
  - `uspecs/uspecs-rc-plugins-codex`
  - Empty repositories; will be populated by the first rc CD run
- [x] create: 3 Release Plugin Repositories if not already provisioned (USER ACTION REQUIRED)
  - `uspecs/uspecs-plugins-claude`
  - `uspecs/uspecs-plugins-augment`
  - `uspecs/uspecs-plugins-codex`
  - Empty repositories; will be populated by the first `release.yml` run
- [x] update: `USPECS_DELIVERY_TOKEN` repository secret (USER ACTION REQUIRED)
  - Extend the fine-grained PAT scope (`Contents: read and write`) to cover the 3 new `uspecs-rc-plugins-{agent}` repositories (and the 3 `uspecs-plugins-{agent}` if not already in scope)

## Technical design

- [x] update: [devops/arch.md](../../specs/devops/arch.md)
  - update: "Version format" - replace the obsolete `-aN` (alpha) scheme with the three-stream scheme: `X.Y.Z-dev` (main), `X.Y.Z-rc` (rc), `X.Y.Z` (release); document the build-suffix shape `+YYYYMMDD-HHMM.SHORT_SHA` for delivered pre-release builds

- [x] update: [devops/dev/release--td.md](../../specs/devops/dev/release--td.md)
  - update: "Key components" - replace single `release.yml`/`release.sh` entry with four manual workflows (`rc.yml`, `release.yml`, `patch.yml`, `validate_patch.yml`) plus one auto-triggered workflow that finalizes patch on merge to `release`; each backed by a script under `scripts/` (`rc.sh`, `release.sh`, `patch.sh`)
  - update: "Key flows" - replace the single diagram with separate flows for "Create rc" (including the `rc -> rc-maint` snapshot step), "Create initial release", "Initiate patch from rc", "Initiate patch from rc-maint", "Create patch (PR merge + auto-finalize)"
  - update: "Key data models / Version transformation" - cover all transitions: `X.Y.Z-dev` (main) -> `X.Y.0-rc` (rc) and `X.Y+1.0-dev` (main bump); `X.Y.0-rc` (rc) -> `X.Y.0` (release) + tag `vX.Y.0` + `X.Y.1-rc` (rc anticipatory); `X.Y.Z-rc` (rc) -> `X.Y.Z` (patch) + `X.Y.Z+1-rc` (rc anticipatory, same-line case only)
  - add: section "Branch model" - long-lived rolling `main`/`rc`/`rc-maint`/`release`; ephemeral `patch-X.Y.Z`; force-push semantics on `rc`, `rc-maint`, and `release`; tags `vX.Y.0` are annotated and immutable; patch tags `vX.Y.Z` (Z>=1) preserve historical points across recreations
  - add: section "Workflow guards" - rc workflow snapshots `rc -> rc-maint` when `rc.major.minor` == `release.major.minor` and `rc-maint` HEAD differs (preserves the about-to-be-replaced rc state), then aborts when `rc` has unpromoted commits not on `release` (with bootstrap exception when `rc` does not exist); release workflow aborts on in-flight `patch-*`, non-zero rc patch, or `vX.Y.0` tag collision on a different commit; patch workflow source is `rc` if `rc.major.minor` == `release.major.minor` else `rc-maint`, and aborts when `patch-X.Y.Z` exists with different content or `release` does not exist; `validate_patch` fails unless `patch.major == release.major`, `patch.minor == release.minor`, `patch.patch == release.patch + 1`
  - add: section "Migration" - lazy bootstrap; `rc` and `release` materialize on first run of `rc.yml`/`release.yml`; pre-cutover tags remain reachable

- [x] update: [devops/dev/cd--td.md](../../specs/devops/dev/cd--td.md)
  - update: "Key components / cd.yml" - matrix gains a `stream` dimension (`dev | rc | release`) alongside `agent`, producing 9 (agent x stream) jobs
  - update: "Key flows" - routing is driven by the source branch (`main` -> dev, `rc` -> rc, `release` -> release); `version.txt` no longer drives routing but still determines the plugin version string; matrix entries whose source branch does not exist are skipped (supports lazy bootstrap)
  - update: "Key data models / Destination Mapping" - add an RC Repository URL column for the three agents (`uspecs-rc-plugins-{claude,augment,codex}`)
  - update: "Key data models / Versioning Schemes" - add "RC Stream" entry (`X.Y.Z-rc+YYYYMMDD-HHMM.SHORT_SHA`, RC Plugin Repository, triggered by push to `rc`); revise "Release Stream" trigger to "push to `release`" (tag `vX.Y.Z` is created on the same commit)
  - add: section "rc CD skip" - rc CD skips commits whose subject starts with `version` AND whose `version.txt` has patch > 0 (suppresses anticipatory bumps `version 2.3.1-rc`, `version 2.3.2-rc`, ...; the initial `version X.Y.0-rc` and developer cherry-picks still fire CD)
  - add: section "Authentication" - all 9 destination repositories are accessed with a single `USPECS_DELIVERY_TOKEN` PAT scoped over all of them
