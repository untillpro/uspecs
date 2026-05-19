---
registered_at: 2026-05-19T17:17:22Z
change_id: 2605191717-per-type-what-guidance
type: feat
scope: softeng
baseline: c62b06a46653680fd2bb3c4bc17dc6416a5898f4
archived_at: 2026-05-19T17:46:46Z
---

# Change request: Per-type guidance for the What section of change.md

## Why

The `## What` section of `change.md` currently has a single generic rule ("without implementation details"), which is too weak: `feat` requests drift into file paths and symbol names, and `fix` requests omit the fault and the trigger flow that would make the bug reproducible. Tailoring the guidance to the Conventional Commits type already carried in frontmatter sharpens authoring and review.

## What

Extend the `## What` guidance in `artdef_change_why_what.md` with per-type rules keyed off the `type:` frontmatter value:

- `feat`: behavior claims only; no file paths, no symbol names; affected domain/context named in prose so reviewers can judge blast radius
- `fix`:
  - symptom (observable wrong outcome)
  - flow: external trigger through the internal causal chain to the symptom, with the fault marked as a step
    - steps may use conceptual labels and/or concrete identifiers (file names, function/method names, config keys, etc.)
    - concrete identifiers are optional; the whole flow can be conceptual
  - corrected behavior claim
- `refactor`, `perf`, `style`: explicit "no behavior change" claim plus the invariant being preserved
- `docs`: what the reader gains and which artifact category is touched
- `build`, `ci`, `chore`: what capability or guarantee changes for contributors, not which files
- `test`: which behavior gains coverage and at which level
- `revert`: the commit being reverted and which behavior returns
- Breaking changes (`breaking: true`, any type): an explicit bullet describing what previously worked stops working or changes shape

## Construction

- [x] update: [bin/prompts/artdef_change_why_what.md](../../../../../bin/prompts/artdef_change_why_what.md)
  - add: per-type guidance subsection under the `## What` placeholder, keyed off the `type:` frontmatter value already written by `softeng.sh`
  - rules to encode, one bullet per type:
    - `feat`: behavior claims only; no file paths, no symbol names; affected domain/context named in prose
    - `fix`:
      - symptom (observable wrong outcome)
      - flow: external trigger through the internal causal chain to the symptom, with the fault marked as a step; steps may use conceptual labels and/or concrete identifiers (files, functions, config keys); concrete identifiers optional
      - corrected behavior claim
    - `refactor`, `perf`, `style`: explicit "no behavior change" claim plus the invariant being preserved
    - `docs`: what the reader gains and which artifact category is touched
    - `build`, `ci`, `chore`: what capability or guarantee changes for contributors, not which files
    - `test`: which behavior gains coverage and at which level
    - `revert`: the commit being reverted and which behavior returns
  - add: cross-cutting note that when `breaking: true` (any type), include an explicit bullet describing what previously worked stops working or changes shape
  - preserve: existing `## Why` guidance and the generic "introductory sentence + items" shape for `## What`

## Quick start

After this change, when authoring `change.md` for a `feat`, the `## What` section reads as behavior claims, e.g.:

```markdown
## What

uchange will refuse to create a change request when the working tree has uncommitted changes:

- Engineer sees an explanatory error
- No Change Folder is created
- No git branch is created
```

For a `fix`, the `## What` section traces the bug from external trigger to symptom with the fault marked inline:

```markdown
## What

upr currently produces an empty PR body when change.md lacks a `## What` section:

- symptom: PR body is the literal string "null"
- flow:
  - upr is invoked on a change.md that has only `## Why`
  - `pr_body.go` reads the What section and returns null
  - **fault**: the body builder in `pr_body.go` does not guard against the null and passes it to the renderer
  - the renderer in `render.go` stringifies null
  - the PR is posted with body "null"
- corrected behavior: PR body falls back to the `## Why` content
```
