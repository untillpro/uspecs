---
registered_at: 2026-02-07T19:42:44Z
change_id: 2602072042-reorg-u-folder
baseline: 43bf936bfc76533153c5e7ca89c8559804387674
archived_at: 2026-02-07T20:22:16Z
---

# Change request: Reorganize u folder naming

## Why

File names in the u folder do not consistently match their command names and use inconsistent prefix patterns. This makes it harder to discover and navigate the files.

## What

Rename action files to match command names:

- actn-dec.md -> actn-udec.md
- actn-how.md -> actn-uhow.md
- actn-impl.md -> actn-uimpl.md
- actn-sync.md -> actn-usync.md
- actn-changes.md -> actn-uchange.md

Rename template files to use tmpl- prefix:

- templates-dec.md -> tmpl-dec.md
- templates-how.md -> tmpl-how.md
- templates-td.md -> tmpl-td.md

Split templates.md into two files:

- tmpl-change.md - Change File Template 1
- tmpl-fd.md - Functional Design Specifications templates (Scenarios File, Requirements File)

Delete templates.md after split.

Update all cross-references in affected files.
