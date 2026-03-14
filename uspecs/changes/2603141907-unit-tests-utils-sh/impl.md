# Implementation plan: Unit tests and utils.sh file section output

## Functional design

- [x] update: [dev/tests.feature](../../specs/devops/dev/tests.feature)
  - add: Unit test scenarios (Developer runs unit tests, Developer runs all tests includes unit tests)
  - update: Feature title and description to include unit tests
  - update: "Developer runs all tests" scenario to include unit tests

## Construction

- [x] update: [u/scripts/_lib/utils.sh](../../u/scripts/_lib/utils.sh)
  - add: `file_section(file, section_id, [vars_map])` function
    - extracts markdown section by ID (format: `## section_id: Title`)
    - excludes subsections (stops at next heading of any level)
    - substitutes `{VAR}` placeholders with values from associative array (nameref)
    - escapes `\` and `&` in values for safe bash parameter expansion
    - fails fast via `error()` for missing file, missing section, or unsubstituted placeholders
    - strips leading/trailing blank lines from output

- [x] create: [tests/unit/utils-file-section.bats](../../../tests/unit/utils-file-section.bats)
  - 15 unit tests for `file_section` function
    - basic extraction (section by ID, last section, subsection exclusion, hyphen/underscore in IDs)
    - variable substitution (all vars, partial vars fail, no vars when no placeholders)
    - edge cases (missing file, missing section, empty section, blank line stripping)
    - special characters (backslashes in values, shell metacharacters like `$()`, backticks, `&`)
