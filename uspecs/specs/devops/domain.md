# Domain: devops

## System

Tools, scripts, and configuration files to assist with development, testing, deployment, and operation.

## External actors

Roles:

- 👤Developer
  - Can modify the codebase. Corresponds to the "Writer" role in GitHub.

Systems:

- ⚙️GitHub
  - A platform that allows users to store, manage, and share code, and to automate related workflows

## Concepts

- Plugin Repository: per-agent per-stream external GitHub repository
  - Rationale: As of 2026-05-04, Augment Code does not support marketplaces in branches; otherwise, we would have a single repository with multiple branches for dev and release streams
- Dev Plugin Repository: per-agent external GitHub repository that holds the development stream of the plugin, updated automatically from `main` while `version.txt` carries a `-dev` suffix
  - Multiple repositories are used, per agent per stream, to allow independent development and release cycles, and to provide a clear separation between stable releases and ongoing development
  - Examples
    - https://github.com/uspecs/uspecs-dev-plugins-claude
    - https://github.com/uspecs/uspecs-dev-plugins-augment
    - https://github.com/uspecs/uspecs-dev-plugins-codex
- Release Plugin Repository: per-agent external GitHub repository that holds the stable release stream of the plugin, updated automatically when a stable `version.txt` is tagged
  - Examples
    - https://github.com/uspecs/uspecs-plugins-claude
    - https://github.com/uspecs/uspecs-plugins-augment
    - https://github.com/uspecs/uspecs-plugins-codex
  
## Contexts

### dev

Development, testing, and release automation.

Relationships:

- 🎯dev -> |service| 👤Developer
  - Development tooling and workflows
  - Test tooling and workflows
- 🎯dev -> |service| 👤Maintainer
  - Release management tooling and workflows
- ⚙️GitHub -> 🎯dev
  - Repository hosting
  - CI/CD automation

### ops

Production operations, monitoring, and incident response.
