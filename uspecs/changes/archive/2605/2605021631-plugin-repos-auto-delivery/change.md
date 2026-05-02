---
registered_at: 2026-05-01T17:07:19Z
change_id: 2605011707-plugin-repos-auto-delivery
baseline: 2e302af568c92c47a30fea056ed4cf989e180031
pre_pr_head: 304e2fa91d54b3bc72933b0382b9ea851fa84c2f
archived_at: 2026-05-02T16:31:11Z
---

# Change request: Auto-deliver plugins to per-agent repos

## Why

- Plugins for each supported AI agent (Claude, Augment, Codex) are consumed from dedicated external repositories, not from this monorepo
- There are differences between plugin structures and formats for each agent
- Consumers need both an up-to-date development stream (between formal releases) and a stable release stream, fed automatically from this monorepo

## What

Add a new `## Concepts` section to `uspecs/specs/devops/domain.md` (between `## External actors` and `## Contexts`) with the following concepts:

- Dev Plugin Repository: per-agent external GitHub repository that holds the development stream of the plugin, updated automatically from `main` while `version.txt` carries a `-dev` suffix
- Release Plugin Repository: per-agent external GitHub repository that holds the stable release stream of the plugin, updated automatically when a stable `version.txt` is tagged

Introduce a **Continuous Delivery** feature (`uspecs/specs/devops/dev/cd.feature`) - automatically deliver plugin contents to per-agent **Plugin Repositories**, where the destination repo and version scheme are driven by the contents of `version.txt`:

- If `version.txt` carries any SemVer pre-release suffix (any `-...`, e.g. `2.3.0-dev`): deliver to the per-agent **Dev Plugin Repositories**
  - https://github.com/uspecs/uspecs-dev-plugins-claude
  - https://github.com/uspecs/uspecs-dev-plugins-augment
  - https://github.com/uspecs/uspecs-dev-plugins-codex
  - Plugin semver: `2.3.0-dev+20260501-1542.a139afbb1aba` (CORE-dev+YYYYMMDD-HHMM.SHORT_SHA, UTC); the `-dev` label is fixed on the cd side and does not depend on the source pre-release tag
- Otherwise (bare `X.Y.Z` with no pre-release suffix): deliver to the per-agent **Release Plugin Repositories**
  - https://github.com/uspecs/uspecs-plugins-claude
  - https://github.com/uspecs/uspecs-plugins-augment
  - https://github.com/uspecs/uspecs-plugins-codex
  - Plugin semver: `X.Y.Z` (no timestamp, no build metadata)

## How

Feature Technical Design for cd.feature is needed:

- New GitHub Actions workflow (cd.yml) that drives the delivery and calls deliver.sh
  - Triggered on push to `main` (typically delivers the dev stream), on tag `v*` (delivers the stable stream, since `release.sh` only writes a stable `version.txt` on the tagged commit), and on `workflow_dispatch` (manual re-run against any ref; routing still follows that ref's `version.txt`)
  - One job per agent via a matrix over `claude | augment | codex` with `fail-fast: false`, so a failure for one agent does not block the others; the workflow status is failed if any agent failed and only failed jobs need to be re-run
  - Inspects `version.txt` to choose Dev vs Release destination, selects the per-agent URL from a hardcoded `agent -> {dev,release} URL` table, clones that repo using `USPECS_DELIVERY_TOKEN`, then invokes `deliver.sh` against the local clone; commits produced by `deliver.sh` are pushed back via `USPECS_DELIVERY_TOKEN`
- Authentication: `USPECS_DELIVERY_TOKEN` is a fine-grained Personal Access Token belonging to a maintainer, stored as a repository secret in this repo
  - Resource owner: `uspecs`; access limited to the six external plugin repos listed above
  - Repository permissions: `Contents: read and write` (sufficient to clone and push); no other permissions granted
  - Commits to plugin repos are authored as the token owner; rotation is the maintainer's responsibility (fine-grained PATs expire at most yearly and must be renewed before expiry)
- scripts/deliver.sh
  - Operates on a pre-cloned destination repo passed as `--marketplace-repo <path>`; reads `version.txt` only to compute the version scheme (dev `CORE-dev+TS.SHORT_SHA` vs stable `X.Y.Z`, toggled by `--release`); does not own the dev-vs-release dispatch or the URL mapping
  - Generates plugin contents via `gen-uspecs-market.py`, then commits and pushes the changes
  - No-op detection: in dev mode every push to `main` produces a fresh version (`CORE-dev+TS.SHORT_SHA`) and therefore a new commit on the Dev Plugin Repository, even when underlying plugin sources are unchanged - this is intentional so dev repos faithfully track every `main` SHA
- scripts/_lib/gen-uspecs-market.py: generates the uspecs market with given parameters
- scripts/templates/: holds the inputs consumed by gen-uspecs-market.py (`actions/*.yaml`, `action-command-claude.md`, `action-skill-generic.md`, `marketplace.json`, `plugin.json`, `README.md.tpl`); gen-uspecs-market.py resolves its templates directory to `<repo-root>/scripts/templates`
- Implementation examples
  - [deploy.sh](deploy.sh) - reference content; adopted as `scripts/deliver.sh`
  - [gen-uspecs-market.py](gen-uspecs-market.py) - reference content; adopted as `scripts/_lib/gen-uspecs-market.py`
  - [templates/](templates) - reference content for `scripts/templates/`

Align the existing release feature with the `-dev` scheme so that `version.txt` on `main` always carries `-dev` (instead of the current `-aN` alpha scheme):

- [release.feature](../../../../specs/devops/dev/release.feature): scenario uses `-dev` for current and bumped dev versions
- [release--td.md](../../../../specs/devops/dev/release--td.md): "Version transformation" describes `X.Y.Z-dev` and bump target `X.Y+1.0-dev`
- [release.sh](../../../../../scripts/release.sh): `validate_version` regex accepts `-dev`; `get_release_version` strips `-dev`; `get_next_dev_version` produces `X.Y+1.0-dev`

References:

- [.github/workflows/release.yml](../../../../../.github/workflows/release.yml)
- [scripts/release.sh](../../../../../scripts/release.sh)
- [version.txt](../../../../../version.txt)
- [.claude/skills](../../../../../.claude/skills)
- [uspecs/specs/devops/domain.md](../../../../specs/devops/domain.md)
- [uspecs/specs/devops/dev/release.feature](../../../../specs/devops/dev/release.feature)
- [uspecs/specs/devops/dev/release--td.md](../../../../specs/devops/dev/release--td.md)

## Domain specifications

- [x] update: [devops/domain.md](../../../../specs/devops/domain.md)
  - add: `## Concepts` section between `## External actors` and `## Contexts`
  - add: "Dev Plugin Repository" concept - per-agent external GitHub repository holding the development stream of the plugin, updated automatically from `main` while `version.txt` carries a `-dev` suffix
  - add: "Release Plugin Repository" concept - per-agent external GitHub repository holding the stable release stream of the plugin, updated automatically when a stable `version.txt` is tagged

## Functional design

- [x] create: [devops/dev/cd.feature](../../../../specs/devops/dev/cd.feature)
  - Feature specification for continuous delivery of plugins to per-agent external repositories
- [x] update: [devops/dev/release.feature](../../../../specs/devops/dev/release.feature)
  - update: replace alpha scheme (`-aN`, e.g. `1.7.0-a4`, `1.8.0-a0`) with development scheme (`-dev`, e.g. `1.7.0-dev`, `1.8.0-dev`) in "Developer triggers release via GitHub Action" scenario

## Provisioning and configuration

- [x] create: `USPECS_DELIVERY_TOKEN` repository secret (USER ACTION REQUIRED)
  - Fine-grained Personal Access Token with `Contents: read and write` on the six plugin repositories
  - Resource owner: `uspecs`
  - Targets: `uspecs-plugins-{claude,augment,codex}`, `uspecs-dev-plugins-{claude,augment,codex}`

## Technical design

- [x] create: [devops/dev/cd--td.md](../../../../specs/devops/dev/cd--td.md)
  - Feature Technical Design: GitHub Actions workflow, deliver.sh logic, URL mapping, authentication
- [x] update: [devops/dev/release--td.md](../../../../specs/devops/dev/release--td.md)
  - update: replace alpha scheme (`-aN`, e.g. `X.Y.Z-aN`, `X.Y+1.0-a0`) with development scheme (`-dev`, e.g. `X.Y.Z-dev`, `X.Y+1.0-dev`) in "Version transformation" section

## Construction

- [x] create: [.github/workflows/cd.yml](../../../../../.github/workflows/cd.yml)
  - GitHub Actions workflow for continuous delivery
  - Matrix over agents (claude, augment, codex)
  - Routing logic based on `version.txt` (dev vs release)
- [x] create: [scripts/deliver.sh](../../../../../scripts/deliver.sh)
  - adopt from [deploy.sh](deploy.sh)
- [x] create: [scripts/_lib/gen-uspecs-market.py](../../../../../scripts/_lib/gen-uspecs-market.py)
  - adopt from [gen-uspecs-market.py](gen-uspecs-market.py)
- [x] create: [scripts/templates/](../../../../../scripts/templates/)
  - adopt from [templates/](templates)
- [x] update: [scripts/release.sh](../../../../../scripts/release.sh)
  - update: `validate_version` regex to accept `-dev`
  - update: `get_release_version` to strip `-dev`
  - update: `get_next_dev_version` to produce `X.Y+1.0-dev`

## Quick start

- Trigger the CD workflow manually via GitHub Actions to verify delivery to Dev Plugin Repositories
