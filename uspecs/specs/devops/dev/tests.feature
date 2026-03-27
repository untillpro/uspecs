Feature: unit, system and e2e tests
  Developer runs automated tests to verify core script behavior

  # python tests/run-tests.py tests/unit
  Scenario: Developer runs unit tests
    When Developer runs unit tests
    Then tests exercise individual shell functions in isolation
    And results are reported per test with pass/fail status

  # python tests/run-tests.py tests/sys
  Scenario: Developer runs system tests
    When Developer runs system tests
    Then tests uses real git operations and curl/gh CLI stubbed
    And results are reported per test with pass/fail status

  # python tests/run-tests.py tests/e2e
  Scenario: Developer runs e2e tests
    When Developer runs e2e tests
    Then tests uses real operations
    And results are reported per test with pass/fail status

  # python scripts/run-tests.py tests
  Scenario: Developer runs all tests
    When Developer runs all tests
    Then unit, system and e2e tests are executed
    And results are reported per test with pass/fail status

  # python scripts/run-tests.py tests/unit "shell metacharacters"
  Scenario: Developer runs tests in parallel using Python runner with pattern
    When Developer runs tests from folder "tests/unit" with filter "shell metacharacters"
    Then tests are discovered recursively from the folder
    And all tests whose names match "shell metacharacters" are executed in parallel
    And each test result is reported as it completes with file path and test name
    And summary reports total tests, failures, and elapsed time

  Rule: Test runner behavior

    Scenario: Skipped tests are reported as failures
      Given a bats test is silently skipped (bats reports "Executed 0 instead of expected 1")
      Then the test is reported as "skip" in output
      And it is counted as a failure in the summary
      And the runner exits with non-zero exit code
