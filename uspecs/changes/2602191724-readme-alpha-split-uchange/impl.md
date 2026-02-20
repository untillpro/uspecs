# Implementation: README alpha+nlia first, split uchange/uarchive

## Functional design

- [x] create: [specs/prod/softeng/archive.feature](../../specs/prod/softeng/archive.feature)
  - add: Gherkin concise scenarios covering the archive change action

## Technical design

- [x] update: [specs/prod/softeng/softeng--arch.md](../../specs/prod/softeng/softeng--arch.md)
  - add: Archive change key flow with sequence diagram referencing actn-uarchive.md
  - add: Generic flow subsection with invariant sequence diagram covering all u* actions

## Construction

- [x] update: [u/actn-uchange.md](../../u/actn-uchange.md)
  - remove: "Archive change" section (flow, parameters)
  - update: title from "Actions: Changes management" to "Action: Create change"

- [x] create: [u/actn-uarchive.md](../../u/actn-uarchive.md)
  - add: archive change flow, parameters, and Gherkin scenario extracted from actn-uchange.md

- [x] update: [README.md](../../../README.md)
  - update: make alpha+nlia curl command the first and prominent install option
  - update: move other install variants into collapsed `<details>` sections marked as not ready

- [x] update: [AGENTS.md](../../../AGENTS.md)
  - add: `uarchive` mapped to `actn-uarchive.md` in triggering instructions

- [x] update: [CLAUDE.md](../../../CLAUDE.md)
  - add: `uarchive` mapped to `actn-uarchive.md` in triggering instructions
