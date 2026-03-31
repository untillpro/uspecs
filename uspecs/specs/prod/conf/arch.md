# Context architecture: prod/conf

## Key components

uspecs components:

- [conf.sh: bash script](../../../u/scripts/conf.sh)
  - Manages uspecs lifecycle (install, update, upgrade, invocation method configuration)
  - Orchestrates version detection, download, and apply
  - Commands: install, update, upgrade, im, apply (internal)

- [_lib/git.sh: bash library](../../../u/scripts/_lib/git.sh)
  - Sources utils.sh
  - Provides git workflow functions: git_pr_info, git_prbranch, git_ffdefault, git_pr, git_changepr, git_mergedef, git_diff
  - Sourced by conf.sh only when running from file (skipped in curl-pipe mode)

- [_lib/utils.sh: bash library](../../../u/scripts/_lib/utils.sh)
  - Source-guarded (loaded once per shell)
  - Provides: error, git_path, temp_create_dir, temp_create_file, sed_inplace, atexit cleanup, section_templ, md_read_frontmatter_field, md_read_title

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
    +-- sources _lib/git.sh (which sources utils.sh)
    +-- full apply flow (copy files, write metadata, inject instructions)
```

### Version detection and download

```text
cmd_install:
  Engineer -> conf.sh install [--alpha|--local] --nlia/--nlic [--pr] [-y]
    |
    +-- for --alpha:
    |     +-- fetch version from GitHub raw (version.txt on main)
    |     +-- fetch latest commit info from GitHub API
    |     +-- download archive for commit ref to temp directory
    |
    +-- for --local (install only):
    |     +-- read version from local repo version.txt
    |     +-- read commit from local git log
    |     +-- skip download; re-invoke current conf.sh directly
    |
    +-- for stable (default):
    |     +-- list tags from GitHub API, pick latest
    |     +-- download archive for tag ref to temp directory
    |
    +-- exec downloaded (or local) conf.sh apply with resolved args

cmd_update_or_upgrade (update):
  Engineer -> conf.sh update [--pr] [-y]
    |
    +-- load current version from uspecs.yml
    |
    +-- for alpha: fetch latest commit, compare with current commit
    |     +-- if same commit: report already up to date, exit
    |     +-- otherwise: set target ref to new commit
    |
    +-- for stable: find latest minor tag matching current major.minor
    |     +-- if same version: report up to date, hint about upgrade if major available
    |     +-- otherwise: set target ref to tag
    |
    +-- download archive, exec downloaded conf.sh apply

cmd_update_or_upgrade (upgrade):
  Engineer -> conf.sh upgrade [--pr] [-y]
    |
    +-- load current version from uspecs.yml
    +-- reject if alpha (alpha uses update instead)
    +-- find latest major tag
    |     +-- if same version: report already up to date, exit
    +-- download archive, exec downloaded conf.sh apply
```

### Apply (internal command)

Invoked by install/update/upgrade after download. Runs from the downloaded (or local) conf.sh.

```text
conf.sh apply <install|update|upgrade> --project-dir <dir> --version <ver> [flags...]
  |
  +-- validate preconditions
  |     +-- uspecs not already installed (install only)
  |     +-- installed version matches expected (update/upgrade only)
  |
  +-- PR sub-flow (if --pr):
  |     +-- remember current branch
  |     +-- fast-forward local default branch (git_ffdefault)
  |     +-- re-check if already up to date after fast-forward
  |
  +-- show operation plan and request confirmation (skipped with -y flag)
  |
  +-- PR sub-flow (if --pr):
  |     +-- create feature branch from default branch (git_prbranch)
  |
  +-- copy files
  |     +-- install: remove uspecs.yml from archive, copy uspecs/u to project
  |     +-- update/upgrade: delete old uspecs/u files, copy new uspecs/u from archive
  |
  +-- write/update uspecs.yml
  |     +-- version, timestamps, invocation_methods
  |     +-- commit info (alpha only)
  |
  +-- inject instructions for each configured invocation method
  |     +-- AGENTS.md (for nlia)
  |     +-- CLAUDE.md (for nlic)
  |
  +-- PR sub-flow (if --pr):
        +-- commit, push to origin, create PR via gh CLI (git_pr)
        +-- switch back to previous branch, delete feature branch
```

### Invocation method management

```text
conf.sh im --add <method> / --remove <method>
  |
  +-- load current invocation_methods from uspecs.yml
  |
  +-- for --add:
  |     +-- skip if method already configured
  |     +-- download source AGENTS.md from GitHub for current version ref
  |     +-- inject instructions into target file (AGENTS.md or CLAUDE.md)
  |
  +-- for --remove:
  |     +-- skip if method not configured
  |     +-- remove instructions block from target file
  |
  +-- update invocation_methods and modified_at in uspecs.yml
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

Alpha version (version contains `-a`, detected by `is_alpha_version`):

```yaml
version: 0.1.0-a0
invocation_methods: [nlia, nlic]
installed_at: 2026-02-14T17:49:00Z
modified_at: 2026-02-14T18:30:00Z
commit: 967257e2d86e4520b48e69d6300c603db359689b
commit_timestamp: 2026-02-14T16:00:00Z
```
