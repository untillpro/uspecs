# Domain: AI-assisted software engineering

## System

Scope:

- Tools and workflows to assist software engineers in designing, specifying, and constructing software systems using AI agents
- Supports both greenfield and brownfield projects

Key features:

- Quick design: no per-project installation or configuration required, great for prototyping and experimentation
- Greenfield and brownfield projects support
- Optional simplified workflow for brownfield projects
- Gherkin language for functional specifications
- Maintaining actual functional specifications
- Maintaining actual architecture and technical design
- Working with multiple domains: by default `prod` and `devops`, can be extended with custom domains

## External actors

Roles:

- 👤Engineer
  - Software engineer interacting with the system

Systems:

- ⚙️AI Agent
  - System that can follow text based instructions to complete multi-step tasks

## Concepts

### Git concepts

- pr_remote: git remote used for pull request operations; "upstream" if it exists, otherwise "origin"
- default_branch: primary branch of the repository that pull requests target (e.g., "main")
- change branch: git branch associated with a change request; named after change-name without the timestamp prefix
- PR branch: git branch with suffix "--pr" created by upr from pr_remote/default_branch; contains a single squashed commit ready for pull request submission

### uspecs concepts

- Change Request: a formal proposal to modify System
- Active Change Request: a Change Request that is being actively worked on
- Invocation Method: how Engineer interacts with uspecs
  - NLI (Natural Language Invocation): instructions injected into agent config files
    - `nlia` (AGENTS.md), `nlic` (CLAUDE.md)
  - CB (Command-Based): direct command execution (to be defined)
- Version Type: classification of installed uspecs version
  - Stable: released versions identified by semantic version tags (e.g., 1.2.3)
  - Alpha: development versions from the main branch
- Functional Design
  - A functional specification focuses on what various outside agents (people using the program, computer peripherals, or other computers, for example) might "observe" when interacting with the system ([stanford](https://web.archive.org/web/20171212191241/https://uit.stanford.edu/pmo/functional-design))
- Technical Design
  - The functional design specifies how a program will behave to outside agents and the technical design describes how that functionality is to be implemented ([stanford](https://web.archive.org/web/20241111203113/https://uit.stanford.edu/pmo/technical-design))
- Construction
  - Software construction refers to the detailed creation and maintenance of software through coding, verification, unit testing, integration testing and debugging (SWEBOK, 2025, chapter 4)

## Contexts

### conf

System lifecycle management and configuration.

Relationships with external actors:

- 🎯conf ->|lifecycle management| 👤Engineer
- 🎯conf ->|configuration| ⚙️AI Agent

### softeng

Software engineering through human-AI collaborative workflows.

Relationships with external actors:

- 🎯softeng -> 👤Engineer
  - Change request management
  - Functional design assistance
  - Architecture and technical design assistance
  - Construction assistance

## Context map

- conf -> |working uspecs| softeng
