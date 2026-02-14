---
registered_at: 2026-02-14T17:49:00Z
change_id: 2602141749-engineer-install-update-upgrade
baseline: 967257e2d86e4520b48e69d6300c603db359689b
---

# Change request: Engineer manages uspecs per project

## Why

Engineers need a way to manage uspecs per project:

- install uspecs with natural language invocation (NLI) support for AGENTS.md or CLAUDE.md
  - later: install uspecs with command-based (CB) invocation support for multiple agent-specific types
- update to the latest minor version (or latest alpha version)
- upgrade to the latest major version
- configure invocation types (add or remove NLI types: nlia, nlic)

## What

### Update prod domain with new concepts

- Invocation Method: NLI (Natural Language Invocation), CB (Command-Based)
- NLI Types: nlia (AGENTS.md), nlic (CLAUDE.md)
- CB Types: multiple agent-specific types (to be defined)
- Version Types:
  - Stable: released versions identified by semantic version tags (e.g., 1.2.3)
  - Alpha: development versions from the main branch

### Install for NLI

README.md contains an Installation section with a Natural Language Invocation subsection.

Installation commands for each NLI type:

```sh
curl -fsSL https://raw.githubusercontent.com/untillpro/uspecs/main/uspecs/u/scripts/manage.sh | bash -s install --nlia
```

```sh
curl -fsSL https://raw.githubusercontent.com/untillpro/uspecs/main/uspecs/u/scripts/manage.sh | bash -s install --nlic
```

Where:

- `--nlia`: enables natural language invocation type for AGENTS.md
- `--nlic`: enables natural language invocation type for CLAUDE.md

Optional flags:

- `--alpha`: installs the latest alpha version from the main branch

Installation fails when:

- no git repository is found in the current directory or any parent directory
- uspecs is already installed for the project (suggest running update instead)

#### Implementation details

- Information is written into a config file in the project directory (`uspecs/u/uspecs.yml`)
- manage.sh `install` flow
  - make validation
  - identify the `ref` for download (main branch for --alpha or latest tag for stable)
  - download the whole repo for the `ref`, unzip
  - update config file with version, commit info, and timestamps
  - copy uspecs/u folder to project
  - if `--nlia` or `--nlic` is specified, update config file with invocation type and inject instructions into AGENTS.md or CLAUDE.md
    - ref. update-from-home.sh for how to inject instructions into AGENTS.md or CLAUDE.md (this script will be eliminated later)

### Config file

YAML configuration file located at `uspecs/u/uspecs.yml` containing version information, installation and modification timestamps, commit metadata (for alpha versions only), and configured invocation types

Example for stable version:

```yaml
# uspecs installation metadata
# DO NOT EDIT - managed by uspecs

version: 1.2.3
invocation_types: [nlia, nlic]
installed_at: 2026-02-14T17:49:00Z
modified_at: 2026-02-14T18:30:00Z
```

Example for alpha version:

```yaml
# uspecs installation metadata
# DO NOT EDIT - managed by uspecs
version: alpha
invocation_types: [nlia, nlic]
installed_at: 2026-02-14T17:49:00Z
modified_at: 2026-02-14T18:30:00Z
# Commit info for alpha versions
commit: 967257e2d86e4520b48e69d6300c603db359689b
commit_timestamp: 2026-02-14T16:00:00Z
```

### Update to the latest minor version

Engineer runs:

```sh
uspecs/u/scripts/manage.sh update
```

Behavior:

- updates to the latest alpha version if currently on alpha (latest commit from main branch)
- updates to the latest minor version if currently on stable (e.g., 1.2.3 -> 1.2.4, not 1.3.0)
- updates configuration file with new version, commit, and timestamps
- preserves configured invocation types

Flow when --project-dir is not specified:

- detect the next version (list tags for stable versions or get the latest commit from main branch for alpha versions)
- if no new minor version is found
  - for alpha: print "Already on the latest alpha version {commit, timestamp}"
  - for stable
    - print "Already on the latest stable minor version"
    - check if upgrade available
      - print "Upgrade available to version X.Y.Z, use `manage.sh upgrade` command to upgrade"
- if new minor version is available
  - print version details and ask for confirmation to proceed with the update
- identify `project-dir` = `script-dir`/../..
- download the next version of manage.sh from the repo for the identified version
- run the latest version with `update --project-dir <project-dir>` to perform the update

Flow when --project-dir is specified:

- remove uspecs/u from project-dir
- copy uspecs/u from `script-dir`/.. to project-dir/uspecs/u
- update config file in project-dir with new version, commit, and timestamps

### Upgrade to the latest major version

Engineer runs:

```sh
uspecs/u/scripts/manage.sh upgrade
```

Same flow as update command, but detects the latest major version instead of latest minor version (e.g., 1.2.3 -> 2.0.0).

Only applicable for stable versions (alpha versions always track main branch).

### Configure invocation types

Engineers can add or remove invocation types:

```sh
uspecs/u/scripts/manage.sh it --add nlia
```

```sh
uspecs/u/scripts/manage.sh it --remove nlic
```

```sh
uspecs/u/scripts/manage.sh it --add nlia --add nlic
```

Behavior:

- `--add <type>`: injects instructions into the corresponding file (AGENTS.md, CLAUDE.md, etc.) if not already present
- `--remove <type>`: removes instructions from the corresponding file
- updates the `invocation_types` list in configuration file
- preserves the current uspecs version
- multiple invocation types can be configured simultaneously
