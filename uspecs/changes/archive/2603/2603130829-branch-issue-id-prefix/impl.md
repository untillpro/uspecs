# Implementation plan: Branch name should start with issue ID

## Functional design

- [x] update: [softeng/uchange.feature](../../../../specs/prod/softeng/uchange.feature)
  - add: Scenario for branch naming with issue URL - branch name prefixed with issue ID
- [x] update: [conf.md](../../../../u/conf.md)
  - update: Branch naming rules to include issue-id prefix when issue URL is provided

## Construction

- [x] update: [scripts/uspecs.sh](../../../../u/scripts/uspecs.sh)
  - add: Function to extract issue ID from issue URL (GitHub, GitLab, Jira, hash-fragment URLs)
  - update: cmd_change_new to use issue-id prefix in branch name when issue URL provided
- [x] update: [tests/sys/uspecs.sh-change-new.bats](../../../../../tests/sys/uspecs.sh-change-new.bats)
  - add: Test cases for branch naming with issue URL (GitHub, GitLab, Jira, hash-fragment)
