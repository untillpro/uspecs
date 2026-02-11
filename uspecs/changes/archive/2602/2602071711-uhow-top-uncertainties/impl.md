# Implementation plan: uhow identifies top 5 uncertainties

## Functional design

- [x] update: [prod/softeng/dec.feature](../../../../specs/prod/softeng/dec.feature)
  - update: Background - change "three uncertainties" to "top five uncertainties", add grouping by topic
  - update: Scenario Outline - parameterize area (identified by AI Agent vs specified by Engineer)
  - update: Examples table - two scenarios with condition and area columns
  - remove: All references to predefined sections and flags

## Construction

- [x] update: [uspecs/u/actn-dec.md](../../../../u/actn-dec.md)
  - update: Background - change to "top five uncertainties", add grouping by topic
  - update: Scenario Outline - parameterize area (identified by AI Agent vs specified by Engineer)
  - update: Examples table - two scenarios with condition and area columns
  - remove: All Definitions sections (no more predefined sections)
  - remove: All forced section parameters (--fd, --td, --prov, --con flags)
  - add: Optional area specification parameter using natural language
- [x] update: [uspecs/u/templates-dec.md](../../../../u/templates-dec.md)
  - update: Add two concise examples (flat structure and grouped structure)
  - remove: "Format with predefined sections" section
