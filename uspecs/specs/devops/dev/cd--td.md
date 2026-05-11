# Feature technical design: continuous delivery

## Key components

- [.github/workflows/cd.yml](../../../../.github/workflows/cd.yml)
  - GitHub Actions workflow orchestrator
  - Triggered on push to `main`, `rc`, or `release` only; pushes to `rc-maint` and `patch-X.Y.Z` do not trigger CD (maintenance previews and in-flight patches publish to the `release` stream through the patch PR merge)
  - Per push event, the source branch determines the active `stream` (`main` -> `dev`, `rc` -> `rc`, `release` -> `release`); only that stream's row is materialized, fanning out across the `agent` matrix dimension (`claude | augment | codex`) into 3 jobs
  - The conceptual delivery surface is 9 (agent x stream) destinations; any single push event activates 3 of them
  - Uses `USPECS_DELIVERY_TOKEN` for repository access

- [deliver.sh: bash script](../../../../scripts/deliver.sh)
  - Automates delivery of plugin contents to external repositories
  - Calls `gen-uspecs-market.py` for generation

- [gen-uspecs-market.py: python script](../../../../scripts/_lib/gen-uspecs-market.py)
  - Core marketplace generator
  - Processes templates and produces per-agent plugin structures

## Key flows

### Continuous Delivery

```text
push to main|rc|release -> cd.yml
                             |
                             +-- selects stream from source branch (main->dev, rc->rc, release->release)
                             +-- fans out across agents (claude|augment|codex) for that stream
                             +-- reads version.txt for the plugin version string (routing already fixed by branch)
                             +-- clones destination repo using USPECS_DELIVERY_TOKEN
                             +-- invokes deliver.sh
                                   |
                                   +-- invokes gen-uspecs-market.py
                                   +-- commits and pushes to destination repo

# Lazy bootstrap: until `rc` (or `release`) exists, no push event for that branch
# can occur, so its CD lane is naturally idle; the trigger is push, not a scheduled
# scan of branches.
```

## Key data models

### Destination Mapping

| Agent   | Dev Repository URL                                   | RC Repository URL                                   | Release Repository URL                           |
|---------|------------------------------------------------------|-----------------------------------------------------|--------------------------------------------------|
| claude  | https://github.com/uspecs/uspecs-dev-plugins-claude  | https://github.com/uspecs/uspecs-rc-plugins-claude  | https://github.com/uspecs/uspecs-plugins-claude  |
| augment | https://github.com/uspecs/uspecs-dev-plugins-augment | https://github.com/uspecs/uspecs-rc-plugins-augment | https://github.com/uspecs/uspecs-plugins-augment |
| codex   | https://github.com/uspecs/uspecs-dev-plugins-codex   | https://github.com/uspecs/uspecs-rc-plugins-codex   | https://github.com/uspecs/uspecs-plugins-codex   |

### Versioning Schemes

- Dev Stream (triggered by push to `main`):
  - Plugin version: `X.Y.Z-dev+YYYYMMDD-HHMM.SHORT_SHA`
  - Destination: Dev Plugin Repository
- RC Stream (triggered by push to `rc`):
  - Plugin version: `X.Y.Z-rc+YYYYMMDD-HHMM.SHORT_SHA`
  - Destination: RC Plugin Repository
- Release Stream (triggered by push to `release`; tag `vX.Y.Z` is created on the same commit by `release.yml` / `patch-finalize.yml`):
  - Plugin version: `X.Y.Z`
  - Destination: Release Plugin Repository

## rc CD skip

To avoid duplicate deliveries from the workflow-authored anticipatory bumps that immediately follow a release/patch, the rc job is skipped when both of the following hold on the rc HEAD commit:

- Commit subject starts with `version`
- `version.txt` patch component is greater than 0 (i.e. `X.Y.Z-rc` with `Z > 0`)

Effects:

- Suppresses anticipatory bumps such as `version 2.3.1-rc`, `version 2.3.2-rc`, ...
- The initial RC cut (`version X.Y.0-rc`) still fires CD because its patch is `0`
- Developer cherry-picks/backports onto `rc` still fire CD because their subjects do not start with `version`

## Authentication

All 9 destination repositories (3 agents x 3 streams) are accessed with a single `USPECS_DELIVERY_TOKEN` PAT. The token is a fine-grained PAT with `Contents: read and write` scope covering:

- `uspecs/uspecs-dev-plugins-{claude,augment,codex}`
- `uspecs/uspecs-rc-plugins-{claude,augment,codex}`
- `uspecs/uspecs-plugins-{claude,augment,codex}`
