---
registered_at: 2026-02-07T16:55:54Z
change_id: 2602071755-rename-uhow-to-udec
baseline: 5eca2b503bb954eb18b2614475da36c534546cef
archived_at: 2026-02-07T17:11:55Z
---

# Change request: Rename uhow to udec

## Why

The command trigger word `uhow` does not clearly convey the purpose of the command - clarifying Change Request design through decisions. Renaming to `udec` better reflects the decision-making nature of the action.

## What

Rename `uhow` command trigger and all related artifacts to `udec`:

- Rename `actn-how.md` to `actn-dec.md`, update internal references (title, command name, How File -> Decision File)
- Rename `templates-how.md` to `templates-dec.md`, update template title
- Rename `how.feature` to `dec.feature`, update scenario references (uspecs-how -> uspecs-dec, How File -> Decision File)
- Update `conf.md`: rename How File artifact to Decision File, change `how.md` to `dec.md`
- Update AGENTS.md and CLAUDE.md: change `uhow` trigger to `udec`, update file reference to `actn-dec.md`
