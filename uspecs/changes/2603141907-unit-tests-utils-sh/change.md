---
registered_at: 2026-03-14T19:07:39Z
change_id: 2603141907-unit-tests-utils-sh
baseline: 2f0386a6071c51c77eadb1fa5e00930c5fd2ee29
---

# Change request: Unit tests and utils.sh file section output

## Why

The tests.feature only covers system and e2e tests but not unit tests. Additionally, utils.sh needs a function to output a section of a given file with variable substitution, and this function needs unit tests.

## What

Extends Feature: system and e2e tests with unit tests:

- Add unit test scenarios to tests.feature
- Add `bats tests/unit` run scenario

New utils.sh function:

- `file_section` function in utils.sh that outputs a section of a given file with variable substitution

Tests for the new function:

- Unit tests for `file_section` in tests/unit/
