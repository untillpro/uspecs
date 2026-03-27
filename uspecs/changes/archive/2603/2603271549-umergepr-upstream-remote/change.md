---
registered_at: 2026-03-26T18:02:01Z
change_id: 2603261802-umergepr-upstream-remote
baseline: 2a11eb0cd5cf6936213e350fbcd95b28c9e5e7a8
archived_at: 2026-03-27T15:49:04Z
---

# Change request: umergepr scenario for upstream remote

## Why

When an upstream remote exists (fork setup), after PR merge the local default branch should be fast-forwarded to pr_remote/default_branch. The WCF detection may be delayed due to eventual consistency so a retry is needed.

## What

New scenario "Default: upstream remote exists" for the umergepr feature:

- After merge, local default branch is fast-forwarded to pr_remote/default_branch by retrying fetch+ff for up to 5 seconds until WCF is detected (eventual consistency)
- Non-critical errors are logged but do not block completion

Additional improvements made alongside:

- E2e test refactoring: removed trap EXIT (causes bats silent failures on Windows), switched to BATS_TEST_TMPDIR for automatic cleanup
- Test runner improvements: unified bash invocation across platforms, added skip-as-failure reporting, added --print-output-on-failure
- Private repository support: added github_curl helper using USPECS_GITHUB_TOKEN, switched archive download to GitHub API tarball endpoint
