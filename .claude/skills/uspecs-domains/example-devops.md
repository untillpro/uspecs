# Domain: devops

Development, testing, delivery, deployment, and operations (monitoring, observability, etc.) aspects of the product

## Overview

Scope:

- Tools, scripts, and configuration files supporting product devops.

Key features:

- Development and test tooling and workflows
- Release management automation
- CI/CD integration with GitHub
- Production operations, monitoring, and incident response

## External actors

Roles:

- 👤Developer
  - Modifies codebase
- 👤Maintainer
  - Makes releases

Systems:

- ⚙️GitHub
  - A platform that allows to store, manage, share code and automate related workflows

---

## Contexts

### dev

Development, testing, and release automation.

Relationships:

```mermaid
graph
  dev["📦dev"]
  Developer["👤Developer"]
  Maintainer["👤Maintainer"]
  GitHub["⚙️GitHub"]
  dev -->|development tooling and workflows| Developer
  dev -->|test tooling and workflows| Developer
  dev -->|release management tooling and workflows| Maintainer
  GitHub -->|repository hosting| dev
  GitHub -->|CI/CD automation| dev
```

### ops

Production operations, monitoring, and incident response.

Relationships:

```mermaid
graph
  ops["📦ops"]
  Maintainer["👤Maintainer"]
  ops -->|monitoring and observability| Maintainer
  ops -->|incident response| Maintainer
```

---

## Context map

```mermaid
graph LR
  dev["📦dev"]
  ops["📦ops"]
  dev -->|deployment automation and tooling| ops
```
