# Feature technical design: release

## Key components

- [rc.yml: GitHub Action](../../../../.github/workflows/rc.yml)
  - Manual trigger (workflow_dispatch); cuts a new `rc` from `main` HEAD
  - Executes `rc.sh`

- [release.yml: GitHub Action](../../../../.github/workflows/release.yml)
  - Manual trigger (workflow_dispatch); promotes `rc` to `release` for the initial `X.Y.0` cut
  - Optional `force` input (default false) bypasses idempotent skip checks; abort guards still apply
  - Executes `release.sh`

- [patch.yml: GitHub Action](../../../../.github/workflows/patch.yml)
  - Manual trigger (workflow_dispatch); branches `patch-X.Y.Z` from either `rc` or `release` based on minor alignment
  - Executes `patch.sh`

- [validate_patch.yml: GitHub Action](../../../../.github/workflows/validate_patch.yml)
  - PR trigger (pull_request to `release`); enforces patch version invariants
  - Inline validation, no script

- [patch-finalize.yml: GitHub Action](../../../../.github/workflows/patch-finalize.yml)
  - Auto-trigger (push to `release`) following a `patch-*` PR merge; (re)creates tag `vX.Y.Z`, deletes the merged patch branch
  - Inline finalization, no script

- [rc.sh: bash script](../../../../scripts/rc.sh)
  - Force-pushes `rc` from `main` HEAD; sets `rc/version.txt` to `X.Y.0-rc`; bumps `main/version.txt` to `X.Y+1.0-dev`

- [release.sh: bash script](../../../../scripts/release.sh)
  - Idempotent steps, each gated by a state check:
    - if `release/version.txt` != `X.Y.0`: force-push `release` from `rc` HEAD and commit "version X.Y.0"
    - if tag `vX.Y.0` does not exist: create annotated tag `vX.Y.0` on `release` HEAD
    - if `rc/version.txt` == `X.Y.0-rc`: bump to `X.Y.1-rc`
  - Aborts before any mutation when tag `vX.Y.0` exists on a commit other than the prospective `release` HEAD; `force=true` bypasses the per-step skip checks but not the abort guards

- [patch.sh: bash script](../../../../scripts/patch.sh)
  - Branches `patch-X.Y.Z` from the appropriate base (`rc` if same major.minor, else `release`); sets `patch/version.txt` to `X.Y.Z`; if same-line, bumps `rc/version.txt` to `X.Y.Z+1-rc`

- [version.txt: text file](../../../../version.txt)
  - Stores current version number per branch
  - Single source of truth for version tracking; format depends on branch (`-dev`, `-rc`, or stable)

## Key flows

### Create rc

```text
Maintainer -> rc.yml (workflow_dispatch from main)
                |
                v
            rc.sh
                |
                +-- reads main/version.txt (X.Y.Z-dev)
                +-- aborts if rc has unpromoted commits not on release (unless rc is missing)
                +-- force-pushes rc from main HEAD
                +-- sets rc/version.txt to X.Y.0-rc
                +-- bumps main/version.txt to X.Y+1.0-dev
```

### Create initial release

```text
Maintainer -> release.yml (workflow_dispatch from rc; optional force input)
                |
                v
            release.sh
                |
                +-- reads rc/version.txt (X.Y.0-rc); target = X.Y.0
                +-- aborts if any patch-X.Y.* exists,
                |   or rc patch != 0,
                |   or tag vX.Y.0 exists on a commit other than the prospective release HEAD
                +-- if release/version.txt != X.Y.0:
                |     force-pushes release from rc HEAD; commits "version X.Y.0"
                +-- if tag vX.Y.0 does not exist:
                |     creates annotated tag vX.Y.0 on release HEAD
                +-- if rc/version.txt == X.Y.0-rc:
                |     bumps rc/version.txt to X.Y.1-rc
                +-- (force=true bypasses the per-step skip checks but not the abort guards)
```

### Initiate patch from rc (same major.minor as release)

```text
Maintainer -> patch.yml (workflow_dispatch, base=rc)
                |
                v
            patch.sh
                |
                +-- reads rc/version.txt (X.Y.Z-rc) and release/version.txt
                +-- target patch = release.patch + 1 (== Z, since rc was bumped after release)
                +-- aborts if patch-X.Y.Z exists or release missing
                +-- branches patch-X.Y.Z from rc HEAD
                +-- sets patch/version.txt to X.Y.Z
                +-- bumps rc/version.txt to X.Y.(Z+1)-rc
```

### Initiate patch from release (older line)

```text
Maintainer -> patch.yml (workflow_dispatch, base=release)
                |
                v
            patch.sh
                |
                +-- reads release/version.txt (X.Y.W) and rc/version.txt (different minor)
                +-- target patch = release.patch + 1 (== W+1)
                +-- aborts if patch-X.Y.(W+1) exists or release missing
                +-- branches patch-X.Y.(W+1) from release HEAD
                +-- sets patch/version.txt to X.Y.(W+1)
                +-- rc unchanged (different line)
```

### Create patch (PR merge + auto-finalize)

```text
Developer -> opens PR patch-X.Y.Z -> release
              |
              v
          validate_patch.yml (pull_request)
              |
              +-- fails unless patch.major == release.major
              +--             AND patch.minor == release.minor
              +--             AND patch.patch == release.patch + 1
              |
              v (PR merged)
          patch-finalize.yml (push to release)
              |
              +-- (re)creates tag vX.Y.Z on release HEAD
              +-- deletes patch-X.Y.Z branch
```

## Key data models

### Version transformation

| Source                       | Action         | Source change           | Sibling change           | Tag      |
|------------------------------|----------------|-------------------------|--------------------------|----------|
| `main`: `X.Y.Z-dev`          | Create rc      | `main` -> `X.Y+1.0-dev` | `rc` -> `X.Y.0-rc`       | -        |
| `rc`: `X.Y.0-rc`             | Create release | `rc` -> `X.Y.1-rc`      | `release` -> `X.Y.0`     | `vX.Y.0` |
| `rc`: `X.Y.Z-rc` (same line) | Initiate patch | `rc` -> `X.Y.Z+1-rc`    | `patch-X.Y.Z` -> `X.Y.Z` | -        |
| `release`: `X.Y.Z-1` (older) | Initiate patch | -                       | `patch-X.Y.Z` -> `X.Y.Z` | -        |
| `patch-X.Y.Z` -> `release`   | Merge patch PR | -                       | `release` -> `X.Y.Z`     | `vX.Y.Z` |

## Branch model

- Long-lived rolling branches:
  - `main`: continuous development; `version.txt` is `X.Y.Z-dev`
  - `rc`: release-candidate stabilization; `version.txt` is `X.Y.Z-rc`; force-pushed on each "Create rc"
  - `release`: stable production; `version.txt` is `X.Y.Z`; force-pushed on each "Create release"; advanced by ordinary merge on each accepted patch PR
- Ephemeral branches:
  - `patch-X.Y.Z`: short-lived hotfix branch; deleted on merge by `patch-finalize.yml`
- Tags:
  - Annotated `vX.Y.0` created (immutable) on `release` HEAD by `release.yml`; create-if-not-exists semantics -- once created, the tag is not moved or recreated
  - Lightweight `vX.Y.Z` (re)created on `release` HEAD by `patch-finalize.yml` for patches
  - Each `vX.Y.Z` tag pins the commit that was promoted to `release` for that version; older tags remain at their original commits even after `release` is force-pushed forward, so historical release points stay reachable

## Workflow guards

- `rc.yml`: aborts when `rc` has commits not present on `release` (unpromoted RC) -- bootstrap exception applies when `rc` does not yet exist
- `release.yml`: aborts when any `patch-X.Y.*` branch exists, when `rc/version.txt` patch component is non-zero (rc must be freshly cut from `main` for the next minor before promotion), or when tag `vX.Y.0` exists on a commit other than the prospective `release` HEAD
- `patch.yml`: aborts when `patch-X.Y.Z` already exists or when `release` does not exist
- `validate_patch.yml`: fails unless `patch.major == release.major`, `patch.minor == release.minor`, and `patch.patch == release.patch + 1`

## Workflow execution model

- `release.yml` runs idempotent steps: each state-changing step is gated by a check on the post-condition and is a no-op when the post-condition already holds (release already at `X.Y.0`; tag `vX.Y.0` already exists; rc already at `X.Y.1-rc`)
- The abort guards above run before any mutation and apply on every invocation regardless of idempotent skips
- An optional `force` workflow input (default false) bypasses the per-step skip checks for the operator who needs to redo a partially-applied state; it does not bypass the abort guards or the tag immutability rule (a colliding tag must be deleted manually before `force=true` will tag elsewhere)

## Migration

- Lazy bootstrap: neither `rc` nor `release` is pre-provisioned
- `rc` materializes on the first `rc.yml` run (force-push from `main`)
- `release` materializes on the first `release.yml` run (force-push from `rc`)
- Pre-cutover tags remain reachable; the new `vX.Y.Z` discipline takes over from the next minor
