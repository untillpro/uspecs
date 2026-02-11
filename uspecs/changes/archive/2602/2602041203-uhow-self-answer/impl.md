# Implementation plan

## Functional design

- [x] update: [softeng/how.feature](../../../../specs/prod/softeng/how.feature)
  - Background: AI Agent identifies uncertainties instead of asks questions
  - Added forced clarification scenarios for each section type
  - Added Provisioning/configuration and Construction scenarios
  - Actions describe self-answering with alternatives behavior

## Construction

- [x] update: [u/actn-how.md](../../../../u/actn-how.md)
  - Removed "numbered list format" rule, added "First alternative is recommended"
  - Added forced flags documentation (--fd, --td, --prov, --con)
  - Added Provisioning/configuration and Construction section conditions
  - Synced Scenarios with how.feature
- [x] update: [u/templates-how.md](../../../../u/templates-how.md)
  - Changed "Q: {Question}" to "{Topical heading}" format with confidence levels
  - Added rationale section and reference guidelines
  - Added example topical headings
