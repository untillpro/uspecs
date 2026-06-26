Feature: unit, system and e2e tests
  Developer runs automated tests to verify core script behavior

  Rule: Test types and scopes

    # python3 tests/run-tests.py tests/unit
    Scenario: Unit tests
      When Developer uses "tests/unit" argument to run unit tests
      Then only unit tests are executed

    # python3 tests/run-tests.py tests/sys
    Scenario: System tests
      When Developer uses "tests/sys" argument to run system tests
      Then only system tests are executed
      And tests uses real git operations and curl/gh CLI stubbed

    # python3 tests/run-tests.py tests/e2e
    Scenario: e2e tests
      When Developer uses "tests/e2e" argument to run e2e tests
      Then only e2e tests are executed
      And tests uses real operations

    # python3 tests/run-tests.py tests
    Scenario: All tests
      When Developer uses "tests" argument to run all tests
      Then all tests are executed

  Rule: Core behavior

    Scenario: Default per-test execution
      When Developer runs tests without --per-file flag
      Then each @test is executed as a separate bats invocation
      And tests are executed in parallel across workers
      And each test result is reported as it completes with file path and test name
      And summary reports total tests, failures, and elapsed time

    Scenario: Skipped tests are failures
      Given a bats test is silently skipped (bats reports "Executed 0 instead of expected 1")
      Then the test is reported as "skip" in output
      And it is counted as a failure in the summary
      And the runner exits with non-zero exit code

  Rule: Options

    # python3 tests/run-tests.py tests/unit {pattern}
    Scenario: Test name pattern
      When Developer runs tests from folder with pattern
      Then only tests whose names contain the pattern are executed
      And each matching test is executed as a separate bats invocation

    # python3 tests/run-tests.py --per-file tests/unit
    Scenario: Per-file execution
      When Developer runs tests with --per-file flag
      Then each .bats file is executed as a single bats invocation
      And tests within each file run sequentially inside that invocation
      And files are executed in parallel across workers
