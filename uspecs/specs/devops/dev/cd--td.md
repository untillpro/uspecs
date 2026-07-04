# Feature technical design: continuous delivery

<!-- markdownlint-disable MD038-->

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

## Target files generation

Destination repositories are generated, not synchronized file-by-file. The generator validates that the destination looks like a managed marketplace repository, deletes every existing destination entry except `.git`, and then writes a complete marketplace tree from the current uspecs source checkout.

```text
deliver.sh
  |
  +-- computes version
  |     +-- release: <CORE>
  |     +-- dev: <CORE>-dev+<UTC timestamp>.<source short sha>
  |
  +-- gen-uspecs-market.py --agent <agent> --uspecs-repo <source> --marketplace-repo <destination>
        |
        +-- validates destination repository guardrails
        +-- clears generated destination content
        +-- copies source artifacts
        +-- renders host-specific action files
        +-- renders marketplace metadata
```

Generated destination layout:

- `LICENSE`
  - Source: `LICENSE`
  - Rule: copied from source repository root.

- `{plugin}/bin/`
  - Source: `bin/`
  - Rule: copied recursively, then generated marketplace constants are substituted in `{plugin}/bin/_lib/meta.sh`.

- `{plugin}/skills/uspecs-*`
  - Source: `.claude/skills/uspecs-*`
  - Rule: copied recursively after source skill frontmatter validation.
  - Validation checks every source `SKILL.md` frontmatter field for plain-scalar YAML values containing `: ` or ` #`, which would require quoting.

- `{plugin}/skills/uspecs-concepts/shared/`
  - Source: `.claude/skills/uspecs-concepts/shared/`
  - Rule: not published as files; matching shared links are inlined into consuming skill content, then the shared output folder is removed.

- `.claude-plugin/marketplace.json`
  - Source: `scripts/templates/marketplace.json`
  - Rule: rendered at destination repository root with resolved marketplace name, description, version, and plugin name.

- `{plugin}/.claude-plugin/plugin.json`
  - Source: `scripts/templates/plugin.json`
  - Rule: rendered inside the plugin directory with resolved plugin name, description, and version.

- `README.md`
  - Source: `scripts/templates/README.md.tpl`
  - Rule: rendered with host name, version, generated timestamp, upstream commit, and install commands.

### Action file generation

- `{plugin}/commands/{action}.md`
  - Source: `scripts/templates/action-command-claude.md` and `scripts/templates/actions/*.yaml`
  - Rule: generated for Claude only.

- `{plugin}/skills/{action}/SKILL.md`
  - Source: `scripts/templates/action-skill-generic.md` and `scripts/templates/actions/*.yaml`
  - Rule: generated for Augment and Codex.

- `scripts/templates/actions/*.yaml` defines each action name and either inline `raw_text` or a referenced body file.
- Action descriptions are read from the corresponding feature title in `uspecs/specs/prod/softeng/{action}.feature`.
- Action options are read by executing `bin/softeng.sh meta options {action}` against the source checkout, except for action YAML entries that use an external body file.
- The generator renders the agent-specific dispatch line from the selected agent configuration and substitutes it into the action body through `{{dispatch}}`.
- Claude receives command files under `{plugin}/commands/`; Augment and Codex receive skill files under `{plugin}/skills/{action}/SKILL.md`.

### Version and stream metadata

- `deliver.sh` computes the marketplace version before generation. Release mode uses the SemVer core from `version.txt`; dev mode appends a UTC timestamp and source short SHA.
- `gen-uspecs-market.py` writes the computed version and stream constants into `{plugin}/bin/_lib/meta.sh`.
- Marketplace and plugin names are resolved from the agent and stream: dev builds use the `uspecs-dev-*` marketplace/plugin naming, while release builds use stable names.
