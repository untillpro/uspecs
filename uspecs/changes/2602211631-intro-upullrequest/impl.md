# Implementation plan: Introduce upr command

## Functional design

- [x] create: [softeng/upr.feature](../../specs/prod/softeng/upr.feature)
  - add: Concise scenarios for PR creation from a change branch (validation, merge, diff, PR creation, error handling)

## Technical design

- [x] update: [softeng/softeng--arch.md](../../specs/prod/softeng/softeng--arch.md)
  - add: `upr` entry in Examples section with action file, input, and output description

## Construction

### Shell scripts

- [x] update: [scripts/_lib/pr.sh](../../u/scripts/_lib/pr.sh)
  - add: `mergedef` command — accepts optional `--validate` flag; without flag: validates preconditions then fetches pr_remote and merges pr_remote/default_branch into change_branch; with `--validate`: runs precondition checks only and outputs `change_branch=...` and `default_branch=...`
  - add: `diff` command — accepts `specs` argument; outputs git diff of $specs_folder between current commit and pr_remote/default_branch; uses `cd` into project dir with relative path to avoid Windows MSYS2 path issues with git
  - add: `changepr` command — creates pr_branch from pr_remote/default_branch, squash-merges change_branch, pushes to origin, creates PR via gh, deletes change_branch; rolls back pr_branch on failure
  - extract: `gh_create_pr` helper — encapsulates repo detection, upstream vs origin handling, and `gh pr create` call; used by both `cmd_pr` and `cmd_changepr` to avoid duplication

- [x] update: [scripts/uspecs.sh](../../u/scripts/uspecs.sh)
  - add: `pr mergedef` subcommand — delegates to `_lib/pr.sh mergedef`
  - add: `pr create` subcommand — delegates to `_lib/pr.sh changepr`; passes through `--title` and `--body` flags
  - add: `diff specs` subcommand — delegates to `_lib/pr.sh diff specs`

### Agent action

- [x] create: [u/actn-upr.md](../../u/actn-upr.md)
  - add: Full action file for upr — validate preconditions first (fail fast), read change.md, ask confirmation, merge default branch, diff+title/body derivation, PR creation, reporting

- [x] create: [u/templates/tmpl-pr.md](../../u/templates/tmpl-pr.md)
  - add: PR title and body formatting template — covers both issue-referenced and plain cases

- [x] update: [u/templates/tmpl-fd.md](../../u/templates/tmpl-fd.md)
  - add: Concise scenario rules, user-facing behavior focus, and `Rule: Edge cases` section with example

### Documentation and triggers

- [x] update: [u/conf.md](../../u/conf.md)
  - add: PR branch naming convention — `{change-name}--pr`

- [x] update: [CLAUDE.md](../../../CLAUDE.md)
  - add: `upr` trigger entry pointing to `uspecs/u/actn-upr.md`

- [x] update: [AGENTS.md](../../../AGENTS.md)
  - add: `upr` trigger entry pointing to `uspecs/u/actn-upr.md`

## Quick start

Create a PR from the active change branch:

```text
upr
```

Agent will confirm, merge the default branch, derive PR title and body from the specs diff, and report the PR URL.
