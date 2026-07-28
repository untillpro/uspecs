# uspecs

uspecs is a framework for AI-assisted software engineering. It keeps design, specifications, implementation plans, construction, and delivery aligned through repository-local artifacts and agent workflows.

## Installation

### Claude Code

```sh
claude plugin marketplace add uspecs/uspecs-plugins-claude
claude plugin install uspecs@uspecs-plugins-claude
```

### Augment Code

```sh
auggie plugin marketplace add uspecs/uspecs-plugins-augment
auggie plugin install uspecs@uspecs-plugins-augment
```

### Codex

```sh
codex plugin marketplace add uspecs/uspecs-plugins-codex
codex plugin add uspecs@uspecs-plugins-codex
```

## Workflow

The core change workflow is:

`uchange` → `uimpl` → `upr` → `umergepr` → `uarchive`

Use `uclarify` to resolve specification uncertainties, `usync` to align a working change with source changes, and `uversion` to check the installed plugin version.

uspecs stores durable specifications under `uspecs/specs/` and active change artifacts under `uspecs/changes/`.

Learn more in the [framework concepts](.claude/skills/uspecs-concepts/SKILL.md) and [framework specifications](uspecs/specs/).
