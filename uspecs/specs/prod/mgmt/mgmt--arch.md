# Context architecture: prod/mgmt

## Key components

uspecs components:

- [manage.sh: bash script](../../../uspecs/u/scripts/manage.sh)
  - Manages uspecs lifecycle (install, update, upgrade, invocation type configuration)
  - Orchestrates version detection, download, and local installation

- uspecs.yml: YAML config file, uspecs/u/uspecs.yml
  - Stores installation metadata (version, timestamps, invocation types, commit info for alpha)
  - Single source of truth for installed uspecs state

External systems:

- GitHub Repository: https://github.com/untillpro/uspecs
  - Provides uspecs releases (tags) and alpha versions (main branch)
  - Source for downloading uspecs archives

Related components:

- AGENTS.md: agent config file
  - Contains instructions for nlia invocation type
  - Managed by: manage.sh (injection/removal of instructions)

- CLAUDE.md: agent config file
  - Contains instructions for nlic invocation type
  - Managed by: manage.sh (injection/removal of instructions)

## Key flows

### Version detection and download

```text
Engineer -> manage.sh (install/update/upgrade)
              |
              +-- determine version type (stable/alpha)
              |
              +-- GitHub Repository
              |     |
              |     +-- for stable: list tags, find latest matching version
              |     +-- for alpha: get latest commit from main branch
              |
              +-- download archive for target ref to temp directory
              |
              +-- unzip archive
```

### Local installation

```text
manage.sh (after download)
  |
  +-- validate preconditions
  |     |
  |     +-- git repository exists
  |     +-- uspecs not already installed (install only)
  |
  +-- copy uspecs/u folder from archive to project root
  |
  +-- write/update uspecs.yml
  |     |
  |     +-- version, timestamps
  |     +-- commit info (alpha only)
  |     +-- invocation_types list
  |
  +-- inject instructions (if invocation types specified)
  |     |
  |     +-- AGENTS.md (for nlia)
  |     +-- CLAUDE.md (for nlic)
  |
  +-- clean up temp directory
```

## Key data models

### Config file structure

Stable version:

```yaml
version: 1.2.3
invocation_types: [nlia, nlic]
installed_at: 2026-02-14T17:49:00Z
modified_at: 2026-02-14T18:30:00Z
```

Alpha version:

```yaml
version: alpha
invocation_types: [nlia, nlic]
installed_at: 2026-02-14T17:49:00Z
modified_at: 2026-02-14T18:30:00Z
commit: 967257e2d86e4520b48e69d6300c603db359689b
commit_timestamp: 2026-02-14T16:00:00Z
```