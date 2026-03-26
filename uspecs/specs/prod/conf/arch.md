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

### Curl-pipe install

When conf.sh is piped via curl (`curl ... | bash -s install ...`), `BASH_SOURCE[0]` is unavailable, so `_lib/git.sh` and `utils.sh` cannot be sourced. The install command handles this in two phases:

```text
Phase 1: self-contained (no local file dependencies)
  curl ... | bash -s install --nlia --alpha
    |
    +-- skip sourcing _lib/git.sh (BASH_SOURCE[0] is not a file)
    +-- parse flags, validate arguments
    +-- fetch version info from GitHub API (curl)
    +-- create temp directory (mktemp), register cleanup (trap)
    +-- download archive (curl + tar)
    +-- exec downloaded conf.sh apply (runs from file)

Phase 2: file-based (downloaded conf.sh apply)
  bash "$temp_dir/uspecs/u/scripts/conf.sh" apply ...
    |
    +-- sources _lib/git.sh and utils.sh normally
    +-- full install flow (copy files, write metadata, inject instructions)
```

### Version detection and download

```text
Engineer -> conf.sh (install/update/upgrade)
              |
              +-- determine version type (stable/alpha/local)
              |
              +-- for local (--local flag, install only):
              |     +-- read version from local repo version.txt
              |     +-- read commit from local git log
              |     +-- skip download; use current conf.sh directly
              |
              +-- GitHub Repository (stable/alpha only)
              |     |
              |     +-- for stable: list tags, find latest matching version
              |     +-- for alpha: get latest commit from main branch
              |
              +-- download archive for target ref to temp directory (stable/alpha only)
              |
              +-- unzip archive (stable/alpha only)
```

### Local installation

```text
conf.sh (after download)
  |
  +-- validate preconditions
  |     |
  |     +-- git repository exists
  |     +-- uspecs not already installed (install only)
  |     +-- working directory is clean (--pr only)
  |
  +-- show operation plan and request confirmation (skipped with -y flag)
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
