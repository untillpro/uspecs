# Implementation Plan

## Technical design

- create: [td.md](td.md)
  - add: Design for uspecs.sh impl next-action command
  - add: Design for actn-impl.md integration with script
  - add: Output format specification for deterministic parsing

## Construction

- update: [uspecs/u/scripts/uspecs.sh](../../../../../uspecs/u/scripts/uspecs.sh)
  - add: cmd_impl_next_action function to analyze Implementation Plan
  - add: Helper functions for section detection and parsing
  - add: Main command handler for `impl next-action`
  - update: Usage documentation

- update: [uspecs/u/actn-impl.md](../../../../../uspecs/u/actn-impl.md)
  - update: Flow section to call uspecs.sh first
  - add: Instructions for parsing script output
  - update: Scenarios to reflect script-driven behavior
  - remove: AI decision-making logic for section creation
