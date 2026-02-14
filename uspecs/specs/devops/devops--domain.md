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
