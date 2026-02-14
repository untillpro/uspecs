---
registered_at: 2026-02-14T17:49:00Z
change_id: 2602141749-engineer-install-update-upgrade
baseline: 967257e2d86e4520b48e69d6300c603db359689b
---

# Change request: Engineer manages uspecs per project

## Why

Engineers need a way to manage uspecs per project:

- install uspecs for natural language invocation (invocation through instructions in AGENTS.md or CLAUDE.md)
  - later: install uspecs for command-based invocation (multiple agent-specific commands)
- update to the latest minor version (or latest alpha version)
- upgrade to the latest major version
- configure invocation method

## What

### Update prod domain with new terminology

- NLI

### Install for NLI

README.md will contain a section Installation with subsection `Natural language invocation`.

Two simple curl commands to download and run the installation command:

```sh
curl -fsSL https://raw.githubusercontent.com/untillpro/uspecs/main/uspecs/u/scripts/manage.sh | bash -s install --nlia
```

```sh
curl -fsSL https://raw.githubusercontent.com/untillpro/uspecs/main/uspecs/u/scripts/manage.sh | bash -s install --nlic
```

Where:

- `--nlia` flag enables natural language invocation using AGENTS.md
- `--nlic` flag enables natural language invocation using CLAUDE.md

Optional flags:

- --alpha: install the latest alpha version (actually from the alpha branch)

Installation command fails if:

- no git repository is found in the current directory or any parent directory
- uspecs is already installed for the project, suggesting running update

#### Implementation details

- Information is written into a config file in the project directory (e.g. `.uspecs/u/uspecs.yml`)
- manage.sh `install` flow
  - make validation
  - identify the `ref` for download (main for alpha or latest tag)
  - Download the whole repo for the `ref`, unzip
  - Update config file with version, copy uspecs/u folder
  - if `--nlia` or `--nlic` is provided, update config file with invocation method and add instructions to AGENTS.md or CLAUDE.md
    - Ref. update-from-home.sh for how to add instructions to AGENTS.md or CLAUDE.md (this script will be eliminated later)

### Config file

yaml file that contains info about version, installation/modification time, commit and commit timestamp (for alpha versions), configured invocation methods

```yaml
# uspecs installation metadata
# DO NOT EDIT
version: 1.2.3
invocation_method: [nlia, nlic]

installed_at: 2026-02-14T17:49:00Z
modified_at: 2026-02-14T18:30:00Z

# For alpha version only
commit: 967257e2d86e4520b48e69d6300c603db359689b
commit_timestamp: 2026-02-14T16:00:00Z
```

### Update to the latest minor version

Engineer runs `uspecs/u/scripts/manage update`

- If the current version is an alpha version, the command updates to the latest alpha version
- If the current version is a stable version, the command updates to the latest minor version (e.g. 1.2.3 -> 1.2.4, but not 1.3.0)
