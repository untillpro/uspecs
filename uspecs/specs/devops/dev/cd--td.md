# Feature technical design: continuous delivery

## Key components

- [.github/workflows/cd.yml](../../../../.github/workflows/cd.yml)
  - GitHub Actions workflow orchestrator
  - Matrix over agents: `claude | augment | codex`
  - Uses `USPECS_DELIVERY_TOKEN` for repository access

- [deliver.sh: bash script](../../../../scripts/deliver.sh)
  - Automates delivery of plugin contents to external repositories
  - Calls `gen-uspecs-market.py` for generation

- [gen-uspecs-market.py: python script](../../../../scripts/_lib/gen-uspecs-market.py)
  - Core marketplace generator
  - Processes templates and produces per-agent plugin structures
  - Inlines shared skill content (see [Domain architecture: Shared skill content](../arch.md))

## Key flows

### Continuous Delivery

```text
GitHub Push/Tag -> cd.yml (matrix)
                     |
                     +-- reads version.txt
                     +-- determines destination (Dev vs Release)
                     +-- clones destination repo using USPECS_DELIVERY_TOKEN
                     +-- invokes deliver.sh
                           |
                           +-- invokes gen-uspecs-market.py
                           +-- commits and pushes to destination repo
```

## Key data models

### Destination Mapping

| Agent   | Dev Repository URL                                   | Release Repository URL                           |
|---------|------------------------------------------------------|--------------------------------------------------|
| claude  | https://github.com/uspecs/uspecs-dev-plugins-claude  | https://github.com/uspecs/uspecs-plugins-claude  |
| augment | https://github.com/uspecs/uspecs-dev-plugins-augment | https://github.com/uspecs/uspecs-plugins-augment |
| codex   | https://github.com/uspecs/uspecs-dev-plugins-codex   | https://github.com/uspecs/uspecs-plugins-codex   |

### Versioning Schemes

- **Dev Stream** (triggered by push to `main` with `-dev` version):
  - Plugin version: `CORE-dev+YYYYMMDD-HHMM.SHORT_SHA`
  - Destination: Dev Plugin Repository
- **Release Stream** (triggered by tag `v*` with stable version):
  - Plugin version: `X.Y.Z`
  - Destination: Release Plugin Repository
