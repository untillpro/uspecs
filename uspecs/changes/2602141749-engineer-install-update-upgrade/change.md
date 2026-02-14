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

### Update prod domain with new terminology

- Invocation Method: NLI (Natural Language Invocation), CB (Command-Based)
- NLI Types: nlia (AGENTS.md), nlic (CLAUDE.md)
- CB Types: multiple agent-specific types (to be defined)

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

- `--alpha`: installs the latest alpha version from the alpha branch

Installation fails when:

- no git repository is found in the current directory or any parent directory
- uspecs is already installed for the project, suggesting running update

#### Implementation details

- Information is written into a config file in the project directory (`uspecs/u/uspecs.yml`)
- manage.sh `install` flow
  - make validation
  - identify the `ref` for download (alpha branch for --alpha or latest tag for stable)
  - download the whole repo for the `ref`, unzip
  - update config file with version, commit info, and timestamps
  - copy uspecs/u folder to project
  - if `--nlia` or `--nlic` is specified, update config file with invocation type and inject instructions into AGENTS.md or CLAUDE.md
    - ref. update-from-home.sh for how to inject instructions into AGENTS.md or CLAUDE.md (this script will be eliminated later)

### Config file

YAML configuration file located at `uspecs/u/uspecs.yml` containing version information, installation and modification timestamps, commit metadata, and configured invocation types

```yaml
# uspecs installation metadata
# DO NOT EDIT - managed by uspecs
version: 1.2.3
invocation_types: [nlia, nlic]  

installed_at: 2026-02-14T17:49:00Z
modified_at: 2026-02-14T18:30:00Z

# For alpha version only
commit: 967257e2d86e4520b48e69d6300c603db359689b
commit_timestamp: 2026-02-14T16:00:00Z
```

### Update to the latest minor version

Engineer runs:

```sh
uspecs/u/scripts/manage.sh update
```

Behavior:

- updates to the latest alpha version if currently on alpha (latest commit in main)
- updates to the latest minor version if currently on stable (e.g., 1.2.3 -> 1.2.4, not 1.3.0)
- updates configuration file with new version, commit, and timestamps
- preserves configured invocation types

Flow if --project-dir is not specified:

- Detect the next version (list tags for stable versions or get the latest commit from main for alpha versions)
- If no new version is found
  - For alpha: print "Already on the latest alpha version"
  - For stable
    - Check if upgrade available
    - print "Already on the latest stable version" or "Upgrade available to version X.Y.Z"
- If new version is available
  - Print version details and ask for confirmation to proceed with the update
- Identify `project-dir` = `script-dir`/../..
- Download the next version of manage.sh from the repo for the identified version
- Run the latest version with `update --project-dir <project-dir>` to perform the update

Flow if --project-dir is specified:

- Remove uspecs/u from project-dir
- Copy uspecs/u from `script-dir`/.. to project-dir/uspecs/u
- Update config file in project-dir with new version, commit, and timestamps

### Upgrade to the latest major version

Engineer runs:

```sh
uspecs/u/scripts/manage.sh upgrade
```

Same as update but checks latest major version (e.g., 1.2.3 -> 2.0.0).

### Configure invocation types

Engineers can add or remove invocation types:

```sh
uspecs/u/scripts/manage.sh it --add nlia
```

```sh
uspecs/u/scripts/manage.sh it --remove nlic
```

Behavior:

- `--add <type>`: injects instructions into the corresponding file (AGENTS.md, CLAUDE.md, etc.) if not already present
- `--remove <type>`: removes instructions from the corresponding file
- updates the `invocation_types` list in configuration file
- preserves the current uspecs version
- multiple invocation types can be configured simultaneously
