# Domain: AI-assisted software engineering (augmented engineering)

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

- Version Type: classification of installed uspecs version
  - Stable: released versions identified by semantic version tags (e.g., 1.2.3)
  - Alpha: development versions from the main branch

See also: [uspecs-concepts/SKILL.md](../../../.claude/skills/uspecs-concepts/SKILL.md)

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
