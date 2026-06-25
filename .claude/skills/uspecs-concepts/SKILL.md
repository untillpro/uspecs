---
name: uspecs-concepts
description: Use this skill to explain the uspecs framework (concepts, folder structure, and actions etc.)
user-invocable: false
---

uspecs is a framework for AI-assisted software engineering. It provides tools and workflows for designing, specifying, and constructing software using AI agents.

## Self-evident

- Computer System (System), Operation, Rule, Concept, Model

## Engineering concepts

- Functional Design
  - A functional specification focuses on what various outside actors (people using the program, computer peripherals, or other computers, for example) might "observe" when interacting with the system ([stanford](https://web.archive.org/web/20171212191241/https://uit.stanford.edu/pmo/functional-design))
- Technical Design
  - The functional design specifies how a program will behave to outside actors and the technical design describes how that functionality is to be implemented ([stanford](https://web.archive.org/web/20241111203113/https://uit.stanford.edu/pmo/technical-design))
- Construction
  - Software construction refers to the detailed creation and maintenance of software through coding, verification, unit testing, integration testing and debugging (SWEBOK, 2025, chapter 4)

## Domain-Driven Design (DDD) concepts

For detailed DDD/domain/context/tactical design authoring and review rules and examples, use [uspecs-domains](../uspecs-domains/SKILL.md).

- Domain: target subject area of a computer system
  - Example domains are `prod` and `devops`
- Subdomain: distinct part of the problem space within a Domain
- Bounded Context (Context): model boundary in the solution space with its own Ubiquitous Language
- Tactical Design Elements: model elements inside a Context, such as Entities, Value Objects, Aggregates, Services, Events, Repositories, and Factories
- Feature: cohesive set of scenarios within a Context

## Change management concepts

- Change Request: a formal proposal to modify the system
- Active Change Request: a Change Request that is being actively worked on
- pr_remote: git remote used for pull request operations; "upstream" if it exists, otherwise "origin"
- default_branch: primary branch of the repository that pull requests target (e.g., "main")
- Change Folder: contains change.md and other artifacts documenting a change (format: ymdHM-{change-name})
- Working Change Folder: a Change Folder with files modified since merge-base with pr_remote/default_branch

Change Folder artifacts:

- change.md - describes the change request (Why/What)
- issue*.md - describes the issue that prompted the change
- fault.md - fault localization log for fix-type changes: tracks investigation efforts while the fault remains unlocalized; persists across uimpl invocations; format is up to the agent

## Specification management concepts

- Domain Design Specifications
  - Domain Specification
  - Bounded Context Specification
- Functional Design Specifications
- Technical Design Specifications

Ref. appropriate skills for explanations of these concepts.

## uspecs folder structure

- uspecs/specs/{domain}/ - domain folder, e.g. `prod`, `devops`
- uspecs/changes/ - active Change Folders
- uspecs/changes/archive/ - archived Change Folders

## Actions

Overview:

- Action can be invoked by  Enineer using various approaches such as command and skills
- Historically action names are prexed with "u", command to invoke action uchange can be uspecs::change

List:

- uchange - create a new Change Request with Change Folder
- uimpl - add next implementation plan section to impl.md (iterative: domain specs -> functional design -> provisioning -> technical design -> construction)
- upr - create a pull request (squash, force-push, open PR)
- umergepr - merge an existing pull request
- uarchive - archive a completed Change Folder
- usync - align Working Change Folder plan and specs with source changes since merge-base (dispatched via softeng.sh action usync)
