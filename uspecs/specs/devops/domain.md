# Domain: devops

## System

Tools, scripts and configuration files to assist with development, testing, deployment, operation.

## External actors

Roles:

- 👤Developer
  - Can modify codebase. Corresponds to the "Writer" role in GitHub.

Systems:

- ⚙️GitHub
  - A platform that allows to store, manage, share code and automate related workflows

## Concepts

- Dev Plugin Repository: per-agent external GitHub repository that holds the development stream of the plugin, updated automatically from `main` while `version.txt` carries a `-dev` suffix.
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
