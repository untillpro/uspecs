# Implementation plan: uhow command for implementation approach

## Functional design

- [x] create: [softeng/how.feature](../../../../specs/prod/softeng/how.feature)
  - Cover: Engineer runs uspecs-how command and AI Agent gives implementation approach idea

## Construction

- [x] create: [u/actn-how.md](../../../../u/actn-how.md)
  - add: Action file for uhow command, following pattern of actn-dec.md
- [x] create: [u/templates-how.md](../../../../u/templates-how.md)
  - add: Template for How File structure
- [x] update: [u/conf.md](../../../../u/conf.md)
  - add: How File to Change Folder System Artifacts
  - remove: Change Technical Design (`td.md`) from Change Folder System Artifacts (line 35)
  - remove: Change Technical Design from Technical Design Specifications (line 66)
- [x] update: [u/actn-impl.md](../../../../u/actn-impl.md)
  - remove: "Last resort: Create Change Technical Design" block (lines 84-90)
  - remove: "Reference Change Technical Design" in Technical design section rules (line 149)
- [x] update: [u/templates-td.md](../../../../u/templates-td.md)
  - remove: Change Technical Design entry (lines 26-27)
- [x] update: [AGENTS.md](../../../../../AGENTS.md)
  - add: uhow trigger instruction pointing to `uspecs/u/actn-how.md`
- [x] update: [CLAUDE.md](../../../../../CLAUDE.md)
  - add: uhow trigger instruction pointing to `uspecs/u/actn-how.md`

## Quick start

Run uhow to get implementation approach idea:

```text
uhow
```

Run uhow when How File already exists to add more details:

```text
uhow
```
