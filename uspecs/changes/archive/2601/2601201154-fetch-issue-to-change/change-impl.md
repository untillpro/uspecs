# Implementation plan: Fetch issue content when creating change

## Functional design

- [x] create: `[softeng/change-req-create.feature](../../specs/prod/softeng/change-req-create.feature)`
  - Cover Developer creates change request scenarios

## Technical design

- [x] update: `[softeng/arch.md](../../specs/prod/softeng/softeng--arch.md)`
  - Describe architecture for fetching issue content when creating change request

## Construction overview

Overview:

- uspecs.sh
  - Add a new subcommand (`change frontmatter`)
  - Get rid of old `change add` (complete removal)
- actn-changes.md
  - copy feature as scenarios from softeng/change-req-create.feature, ref. actn-impl.md as example
  - Update flow to create folder/change.md directly instead of using change.tmp
  - Update to call new `uspecs.sh change frontmatter` command

## Construction

- [x] update: `[uspecs/u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)`
  - Add `change frontmatter` subcommand to add frontmatter to existing change.md
  - Remove `change add` subcommand
- [x] update: `[uspecs/u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)`
  - Add `--issue-url` parameter support to `change frontmatter` command
  - When provided, add `uspecs.issue_url: <url>` to frontmatter
- [x] update: `[uspecs/u/actn-changes.md](../../u/actn-changes.md)`
  - Add Gherkin scenarios from change-req-create.feature
  - Update workflow to create folder and change.md directly
  - Update to call `uspecs.sh change frontmatter` instead of `change add`
- [x] update: `[uspecs/u/actn-changes.md](../../u/actn-changes.md)`
  - Update Flow section to handle both scenarios (with and without issue reference)
  - Add conditional logic for calling uspecs.sh with or without --issue-url parameter
- [x] update: `[uspecs/u/templates.md](../../u/templates.md)`
  - Add frontmatter format example showing optional issue_url field
