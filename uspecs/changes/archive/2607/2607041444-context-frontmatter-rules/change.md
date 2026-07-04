---
change_id: 2607041123-context-frontmatter-rules
type: feat
domains: [prod]
scope: [softeng]
---

# Change request: Context frontmatter rules

## Why

The softeng context model needs explicit frontmatter so agents can preserve context metadata consistently across specification workflows. Change creation and pull request preparation should describe how that metadata is created and consumed, so reviewers can understand affected domains without relying on ad hoc prose.

## What

This change introduces frontmatter behavior for the prod domain's softeng context workflows:

- Context specifications expose consistent metadata that agents can read as part of the context model.
- Change creation includes scenario rules for deriving and writing change frontmatter from affected domain information.
- Pull request preparation uses available change frontmatter to communicate change identity, type, and affected domains.
- The new behavior keeps existing collaborative software engineering workflows recognizable while making context metadata explicit.
- Tests that covers the behavior of the new frontmatter rules are included in the change

## How

Decisions:

- Model YAML frontmatter as explicit softeng metadata in the context model, keeping `ChangeRequest` as the owner for change-level fields such as `change_id`, `type`, `domains`, `scope`, `breaking`, and `issue_url`.
- Keep change frontmatter creation in the existing `uchange` instruction flow: `softeng.sh` detects whether domain specs exist, and the emitted prompt rules instruct the AI Agent to infer affected domains and write `domains` as a YAML flow list.
- Specify PR behavior in the existing `upr` artifact rules, using `change.md` frontmatter for PR title, commit subject/body, and PR body presentation without introducing a new PR artifact format.
- Cover the behavior through the existing softeng feature specs and system tests for `uchange` and `upr`.

Out of scope:

- Rewriting archived change requests to add or normalize frontmatter.
- Replacing the existing markdown frontmatter helpers with a general YAML parser.
- Adding pull request host behavior beyond the current `gh`-based workflow.

References:

- [softeng context model](../../../../../uspecs/specs/prod/softeng/context.md)
- [change request scenarios](../../../../../uspecs/specs/prod/softeng/uchange.feature)
- [pull request scenarios](../../../../../uspecs/specs/prod/softeng/upr.feature)
- [softeng action script](../../../../../bin/softeng.sh)
- [change creation prompt](../../../../../bin/prompts/instr_uchange.md)
- [domain frontmatter prompt](../../../../../bin/prompts/artdef_change_domains.md)
- [change request system tests](../../../../../tests/sys/softeng.sh-action-uchange.bats)
- [pull request system tests](../../../../../tests/sys/softeng.sh-action-upr.bats)

## Domain design

- [x] update: [prod/softeng/context.md](../../../../specs/prod/softeng/context.md)
  - add: context model representation for YAML frontmatter metadata owned by `ChangeRequest`
  - update: `ChangeRequest` model details so frontmatter-backed fields are explicit for change creation and PR preparation
  - update: `PullRequest` model behavior so PR artifact preparation consumes change frontmatter through the existing `upr` workflow
  - add: model rules for deriving affected-domain frontmatter during `uchange` and consuming change frontmatter during `upr`

## Functional design

- [x] update: [prod/softeng/uchange.feature](../../../../specs/prod/softeng/uchange.feature)
  - update: change creation scenarios so `change.md` frontmatter creation is explicit for `change_id`, `type`, optional `issue_url`, and affected `domains`
  - add: scenario coverage for allowed `type` values as uchange-supported Conventional Commits values

- [x] update: [prod/softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: PR artifact scenarios so `upr` consumption of `change.md` frontmatter is explicit for title, commit message, and PR body
  - add: scenario coverage that PR body preserves visible YAML frontmatter, including affected `domains` when present

## Construction

### Tests

- [x] update: [sys/softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - target: `uchange.feature` `Scenario Outline: Basic change request creation`
    - cover: `change_frontmatter` artifact exposes `change_id` and `type`, and omits `issue_url` when no issue URL is supplied
  - target: `uchange.feature` `Rule: Change frontmatter` / `Scenario: Allowed change request types`
    - cover: some values from allowed `ChangeRequest.type` mentioned
  - target: `uchange.feature` `Rule: Change frontmatter` / `Scenario Outline: Domain frontmatter emission`
    - cover: emitted instructions set `domains` in `change.md` frontmatter as a YAML flow list and require best-effort domain inference

- [x] update: [sys/softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - target: `upr.feature` `Rule: PR artifacts` / `Scenario Outline: Construct PR title and commit message from frontmatter`
    - cover: PR title and commit message use frontmatter `type`, optional `scope`, optional `breaking`, and optional `issue_url`
  - target: `upr.feature` `Rule: PR artifacts` / `Scenario Outline: Construct PR body`
    - cover: PR body wrapping preserves every YAML frontmatter line inside the `yaml` fenced block

### Implementation

- [x] update: [prompts/artdef_change_domains.md](../../../../../bin/prompts/artdef_change_domains.md)
  - update: domain frontmatter wording so emitted instructions explicitly set `domains` in `change.md` frontmatter
  - preserve: scanning `uspecs/specs/*/domain.md`, deriving directory names, and best-effort inference without asking the Engineer

- [x] update: [prompts/instr_uchange.md](../../../../../bin/prompts/instr_uchange.md)
  - update: change frontmatter preparation wording so `domains` remains an addition to the prepared `change.md` frontmatter when domain specifications exist
