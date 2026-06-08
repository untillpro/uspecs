---
change_id: 2606081310-inline-shared-skill-content
type: build
domains: [devops]
scope: [dev]
---

# Change request: Inline shared skill content during marketplace build

## Why

Several knowledge skills duplicate the same content - notably the artifact path list shared by `uspecs-td` and `uspecs-sec-td`, and a verbatim to-do format Rules block across `uspecs-sec-domains`, `uspecs-sec-fd`, and `uspecs-sec-td`. The source already carries "same text as ..." TODO markers acknowledging this drift risk. We want a single source of truth for shared content while keeping published skills self-contained.

## What

The marketplace build gains a transclusion step for knowledge skills:

- Shared skill content is authored once under `uspecs-concepts/shared/` and reused across other skills, removing duplicated rules and path lists that currently risk drifting apart.
- During marketplace generation, sibling-relative references resolving to `uspecs-concepts/shared/` (i.e. links of the form `../uspecs-concepts/shared/<name>.md`) are inlined into each published skill. Links to any other location are left untouched.
- The `uspecs-concepts/shared/` source files are excluded from the published output, since their content is inlined wherever it is used; installed skills remain self-contained with no cross-skill link resolution at runtime.
- Contributors maintain shared conventions in one place, and the existing "same text as ..." drift markers are eliminated.

## Technical design

- [x] update: [devops/arch.md](../../../../specs/devops/arch.md)
  - add: "Shared skill content" convention section documenting the `uspecs-concepts/shared/` source location, the sibling-relative `../uspecs-concepts/shared/<name>.md` reference form, build-time inlining, and exclusion of the `shared/` source from published output
- [x] update: [devops/dev/cd--td.md](../../../../specs/devops/dev/cd--td.md)
  - update: the `gen-uspecs-market.py` component to note it inlines shared skill content, referencing the Domain architecture convention section

## Construction

### Tests

- [x] update: [tests/e2e/deliver.bats](../../../../../tests/e2e/deliver.bats)
  - add: scenario asserting shared snippet content is inlined into consuming skills in the generated marketplace
  - add: scenario asserting `uspecs-concepts/shared/` is absent from the generated plugin output
  - add: scenario asserting no `../uspecs-concepts/shared/` link remains in any published `SKILL.md`
  - add: scenario asserting generation fails with a clear error when a referenced shared snippet file is missing

### Shared snippets

- [x] create: [uspecs-concepts/shared/todo-format.md](../../../../../.claude/skills/uspecs-concepts/shared/todo-format.md)
  - Shared to-do list format rules block currently duplicated across `uspecs-sec-domains`, `uspecs-sec-fd`, and `uspecs-sec-td`
- [x] create: [uspecs-concepts/shared/td-artifact-paths.md](../../../../../.claude/skills/uspecs-concepts/shared/td-artifact-paths.md)
  - Shared technical-spec artifact path list currently duplicated across `uspecs-td` and `uspecs-sec-td`

### Consuming skills

- [x] update: [uspecs-sec-domains/SKILL.md](../../../../../.claude/skills/uspecs-sec-domains/SKILL.md)
  - replace: duplicated to-do format rules with a link to `../uspecs-concepts/shared/todo-format.md`
- [x] update: [uspecs-sec-fd/SKILL.md](../../../../../.claude/skills/uspecs-sec-fd/SKILL.md)
  - replace: duplicated to-do format rules with a link to `../uspecs-concepts/shared/todo-format.md`
- [x] update: [uspecs-sec-td/SKILL.md](../../../../../.claude/skills/uspecs-sec-td/SKILL.md)
  - replace: duplicated to-do format rules with a link to `../uspecs-concepts/shared/todo-format.md`
  - replace: duplicated artifact path list with a link to `../uspecs-concepts/shared/td-artifact-paths.md`
  - remove: the `// TODO Same text as in uspecs-sec` drift marker
- [x] update: [uspecs-td/SKILL.md](../../../../../.claude/skills/uspecs-td/SKILL.md)
  - replace: duplicated artifact path list with a link to `../uspecs-concepts/shared/td-artifact-paths.md`

### Generator

- [x] update: [_lib/gen-uspecs-market.py](../../../../../scripts/_lib/gen-uspecs-market.py)
  - add: transclusion step in the knowledge-skill copy loop that, for each copied `*.md`, replaces sibling-relative links resolving to `../uspecs-concepts/shared/<name>.md` with the referenced file's content
  - update: skill copy logic to exclude the `uspecs-concepts/shared/` directory from the generated output
  - add: error and exit when a referenced shared snippet file is missing
