# Context architecture: prod/conf

## Key components

uspecs components:

- [conf.sh: bash script](../../../uspecs/u/scripts/conf.sh)
  - Manages uspecs lifecycle (install, update, upgrade, invocation method configuration)
  - Orchestrates version detection, download, and local installation

- uspecs.yml: installation metadata file, uspecs/u/uspecs.yml
  - Stores installation metadata (version, timestamps, invocation methods, commit info for alpha)
  - Single source of truth for installed uspecs state

External systems:

- GitHub Repository: https://github.com/untillpro/uspecs
  - Provides uspecs releases (tags) and alpha versions (main branch)
  - Source for downloading uspecs archives

Related components:

- AGENTS.md: agent config file
  - Contains instructions for nlia invocation method
  - Managed by: conf.sh (injection/removal of instructions)

- CLAUDE.md: agent config file
  - Contains instructions for nlic invocation method
  - Managed by: conf.sh (injection/removal of instructions)

## Key flows

### Version detection and download

```text
Engineer -> conf.sh (install/update/upgrade)
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
conf.sh (after download)
  |
  +-- validate preconditions
  |     |
  |     +-- git repository exists
  |     +-- uspecs not already installed (install only)
  |
  +-- remove uspecs.yml from archive (prevent overwriting local metadata)
  |
  +-- copy uspecs/u folder from archive to project root
  |
  +-- write/update uspecs.yml
  |     |
  |     +-- version, timestamps
  |     +-- commit info (alpha only)
  |     +-- invocation_methods list
  |
  +-- inject instructions (if invocation methods specified)
  |     |
  |     +-- AGENTS.md (for nlia)
  |     +-- CLAUDE.md (for nlic)
  |
  +-- clean up temp directory
```

## Key data models

### Installation metadata file structure

Stable version:

```yaml
version: 1.2.3
invocation_methods: [nlia, nlic]
installed_at: 2026-02-14T17:49:00Z
modified_at: 2026-02-14T18:30:00Z
```

Alpha version:

```yaml
version: alpha
invocation_methods: [nlia, nlic]
installed_at: 2026-02-14T17:49:00Z
modified_at: 2026-02-14T18:30:00Z
commit: 967257e2d86e4520b48e69d6300c603db359689b
commit_timestamp: 2026-02-14T16:00:00Z
```
