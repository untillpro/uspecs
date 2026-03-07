Feature: uspecs.sh tests
  Developer runs automated tests for uspecs.sh to verify core script behavior

  Scenario: Developer runs system tests
    When Developer runs uspecs.sh system tests
    Then tests exercise uspecs.sh as a black box with real git operations and gh CLI stubbed
    And results are reported per test with pass/fail status

  Scenario: Developer runs e2e tests
    When Developer runs uspecs.sh e2e tests
    Then tests exercise uspecs.sh as a black box with real git operations and real gh CLI
    And results are reported per test with pass/fail status

