Feature: system and e2e tests
  Developer runs automated tests to verify core script behavior

  # bats tests/sys
  Scenario: Developer runs system tests
    When Developer runs system tests
    Then tests uses real git operations and curl/gh CLI stubbed
    And results are reported per test with pass/fail status

  # bats tests/e2e
  Scenario: Developer runs e2e tests
    When Developer runs e2e tests
    Then tests uses real operations
    And results are reported per test with pass/fail status

  # bats --recursive tests
  Scenario: Developer runs all tests
    When Developer runs all tests
    Then system and e2e tests are executed
    And results are reported per test with pass/fail status
