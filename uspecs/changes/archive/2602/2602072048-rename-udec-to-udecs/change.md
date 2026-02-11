---
registered_at: 2026-02-07T20:35:15Z
change_id: 2602072034-rename-udec-to-udecs
baseline: 471f0bc11a936540b100ac8620a43a39794fdd36
archived_at: 2026-02-07T20:48:43Z
---

# Change request: Rename udec command to udecs

## Why

The command name `udec` and its associated file `dec.md` use a singular abbreviation. Renaming to `udecs` and `decs.md` improves consistency and clarity by indicating the file contains multiple decisions.

## What

Rename the udec command and its artifacts:

- Rename command trigger word from `udec` to `udecs`
- Rename action file from `actn-udec.md` to `actn-udecs.md`
- Rename Decision File artifact from `dec.md` to `decs.md`
- Update all references across configuration, templates, triggering instructions, and action files
