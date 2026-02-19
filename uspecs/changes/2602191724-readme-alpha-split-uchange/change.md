---
registered_at: 2026-02-19T17:25:18Z
change_id: 2602191724-readme-alpha-split-uchange
baseline: e8d45fcb56095b7d9b5e96894fffd053d56fe1e7
---

# Change request: README alpha+nlia first, split uchange/uarchive

## Why

README.md should present the recommended alpha+nlia install path first, with other options collapsed since they are not ready. The `actn-uchange.md` file combines two distinct concerns - creating a change and archiving a change - which should be separated into their own action files for clarity.

## What

Update README.md installation section:

- Make the alpha+nlia curl command the first and prominent install option
- Move all other install variants into collapsed `<details>` sections marked as not ready

Split `uspecs/u/actn-uchange.md` into two files:

- `uspecs/u/actn-uchange.md` - retains only the create change flow, definitions, and scenarios
- `uspecs/u/actn-uarchive.md` - contains the archive change flow with a concise Gherkin scenario

Add feature file for archive change:

- `uspecs/specs/prod/softeng/archive.feature` - Gherkin scenarios covering the archive change action

Update cross-references:

- Update `AGENTS.md` and `CLAUDE.md` triggering instructions to map `uarchive` to `actn-uarchive.md`
