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

- Information is written into an installation metadata file in the project directory (`uspecs/u/uspecs.yml`)
- manage.sh `install` flow
  - validate: git repository exists, uspecs is not already installed
  - identify the `ref` for download (main branch for --alpha or latest tag for stable)
  - download the whole repo archive for the `ref` into a temp directory, unzip
  - copy uspecs/u folder from the unzipped repo to project root
  - write installation metadata file (`uspecs/u/uspecs.yml`) with version, timestamps (and commit info for alpha)
  - if `--nlia` or `--nlic` is specified, update installation metadata file with invocation types and inject instructions into AGENTS.md or CLAUDE.md
    - ref. update-from-home.sh for how to inject instructions into AGENTS.md or CLAUDE.md (this script will be eliminated later)
  - clean up temp directory

### Installation metadata file

YAML file located at `uspecs/u/uspecs.yml` containing version information, installation and modification timestamps, commit metadata (for alpha versions only), and configured invocation types

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

### Update

Engineer runs:

```sh
uspecs/u/scripts/manage.sh update
```

Behavior:

- for alpha: updates to the latest commit from main branch
- for stable: updates to the latest minor version (e.g., 1.2.3 -> 1.2.4, not 1.3.0)
- updates installation metadata file with new version, timestamps (and commit info for alpha)
- preserves configured invocation types

Flow when --project-dir is not specified:

- detect the next version
  - for alpha: get the latest commit from main branch
  - for stable: list tags and find the latest minor version
- if no new version is found
  - for alpha: print "Already on the latest alpha version {commit, timestamp}"
  - for stable
    - print "Already on the latest stable minor version"
    - check if major upgrade available
      - print "Upgrade available to version X.Y.Z, use `manage.sh upgrade` command"
- if new version is available
  - print version details and ask for confirmation to proceed
- after confirmation
  - identify `project-dir` as three levels up from the manage.sh script location
  - download manage.sh for the target version from the repo into a temp directory
  - run the downloaded manage.sh with `update --project-dir <project-dir>` to perform the update

Flow when --project-dir is specified (called by the downloaded manage.sh):

- remove uspecs/u from project-dir
- copy uspecs/u from the downloaded repo to project-dir/uspecs/u
- update installation metadata file in project-dir with new version, timestamps (and commit info for alpha)

### Upgrade to the latest major version

Engineer runs:

```sh
uspecs/u/scripts/manage.sh upgrade
```

Same flow as update, but detects the latest major version instead of latest minor version (e.g., 1.2.3 -> 2.0.0).

Only applicable for stable versions. Fails with an error if run on alpha (alpha versions always track the latest commit from main branch, use update instead).

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
- updates the `invocation_types` list in installation metadata file
- preserves the current uspecs version
- multiple invocation types can be configured simultaneously
