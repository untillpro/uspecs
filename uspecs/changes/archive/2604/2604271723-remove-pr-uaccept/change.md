---
registered_at: 2026-04-27T17:14:43Z
change_id: 2604271714-remove-pr-uaccept
baseline: d95aaa711676d69be0e2faae44aa5396b866312d
archived_at: 2026-04-27T17:23:47Z
---

# Change request: Remove pr-uaccept feature

## Why

The `pr-uaccept` GitHub Actions workflow was introduced to automate "accept the PR via a comment" but its responsibilities (archive active changes, squash-merge, delete the branch) are already covered by the local `umergepr` action. Maintaining the workflow, its script, and its specifications adds complexity without delivering value beyond what `umergepr` provides.

## What

Remove the `pr-uaccept` feature in its entirety:

- Functional and technical specifications under `uspecs/specs/devops/dev/pr-management*`
- GitHub Actions workflow `.github/workflows/pr-uaccept.yml`
- Helper script `scripts/pr-uaccept.sh`

After this change, accepting a PR is performed by the Engineer running `umergepr` locally. No comment-driven automation remains.

## Functional design

- [x] delete: `[devops/dev/pr-management.feature](../../../../specs/devops/dev/pr-management.feature)`

## Technical design

- [x] delete: `[devops/dev/pr-management--td.md](../../../../specs/devops/dev/pr-management--td.md)`

## Construction

- [x] delete: `[.github/workflows/pr-uaccept.yml](../../../../../.github/workflows/pr-uaccept.yml)`
- [x] delete: `[scripts/pr-uaccept.sh](../../../../../scripts/pr-uaccept.sh)`
