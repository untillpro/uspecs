# Implementation plan: Optimize scenario names

## Functional design

- [x] update: [softeng/uchange.feature](../../../../specs/prod/softeng/uchange.feature)
  - update: scenario names to be condition/outcome-focused instead of command-focused, following upr.feature style

## Construction

- [x] update: [tests/sys/uspecs.sh-change-new.bats](../../../../../tests/sys/uspecs.sh-change-new.bats)
  - update: test names to match corresponding scenario names from uchange.feature
