# Implementation: README alpha+nlia first, split uchange/uarchive

## Functional design

- [x] create: [specs/prod/softeng/uarchive.feature](../../specs/prod/softeng/uarchive.feature)
  - add: Gherkin scenarios covering the archive change action

- [x] move: [specs/prod/softeng/uchange.feature](../../specs/prod/softeng/uchange.feature)
  - rename: change.feature -> uchange.feature

- [x] move: [specs/prod/softeng/udecs.feature](../../specs/prod/softeng/udecs.feature)
  - rename: decs.feature -> udecs.feature

- [x] move: [specs/prod/softeng/uhow.feature](../../specs/prod/softeng/uhow.feature)
  - rename: how.feature -> uhow.feature

- [x] move: [specs/prod/softeng/uimpl.feature](../../specs/prod/softeng/uimpl.feature)
  - rename: impl.feature -> uimpl.feature

- [x] move: [specs/prod/softeng/usync.feature](../../specs/prod/softeng/usync.feature)
  - rename: sync.feature -> usync.feature

## Technical design

- [x] update: [specs/prod/softeng/softeng--arch.md](../../specs/prod/softeng/softeng--arch.md)
  - remove: "Create change" and "Implement change" specific sequence diagrams
  - add: Generic flow invariant sequence diagram covering all u* actions
  - add: Examples subsection listing actions and their artifacts

## Construction

- [x] update: [u/actn-uchange.md](../../u/actn-uchange.md)
  - remove: "Archive change" section (flow, parameters)
  - update: title from "Actions: Changes management" to "Action: Create change"
  - add: "## Overview" section with description
  - update: section renamed to "## Instructions" with consistent format

- [x] create: [u/actn-uarchive.md](../../u/actn-uarchive.md)
  - add: archive change flow, parameters, and Gherkin scenario extracted from actn-uchange.md
  - add: "## Overview" and "## Instructions" sections for consistent format

- [x] update: [README.md](../../../README.md)
  - update: make alpha+nlia curl command the first and prominent install option
  - update: move other install variants into collapsed `<details>` sections marked as not ready

- [x] update: [AGENTS.md](../../../AGENTS.md)
  - add: `uarchive` mapped to `actn-uarchive.md` in triggering instructions

- [x] update: [CLAUDE.md](../../../CLAUDE.md)
  - add: `uarchive` mapped to `actn-uarchive.md` in triggering instructions

- [x] update: [u/actn-udecs.md](../../u/actn-udecs.md)
  - add: "## Instructions" section with consistent format and Parameters structure

- [x] update: [u/actn-uhow.md](../../u/actn-uhow.md)
  - update: title to "Action: How"
  - add: "## Instructions" section with consistent format and Parameters structure

- [x] update: [u/actn-uimpl.md](../../u/actn-uimpl.md)
  - add: "## Overview" and "## Instructions" sections with consistent format

- [x] update: [u/actn-usync.md](../../u/actn-usync.md)
  - add: "## Overview" and "## Instructions" sections with Parameters and Flow
