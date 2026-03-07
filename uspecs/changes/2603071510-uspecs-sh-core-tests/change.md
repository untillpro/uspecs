---
registered_at: 2026-03-07T15:10:50Z
change_id: 2603071510-uspecs-sh-core-tests
baseline: d30e4a6e630c0cb6ad0e1563e7901f258f33ce6b
---

# Change request: Core tests for uspecs.sh

## Why

`uspecs.sh` is the central script for the uspecs workflow but currently has no automated tests. Adding core tests ensures the script behaves correctly for the most common developer operations and prevents regressions.

## What

Add core automated tests for `uspecs.sh` covering system and e2e test scenarios, including technical design:

Scenarios:

- Developer runs system tests
- Developer runs e2e tests

Technical design:

- Test structure and approach for testing `uspecs.sh`
