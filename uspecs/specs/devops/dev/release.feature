Feature: Release management
  Four-branch release cycle with `main` (dev), `rc` (release candidate for the next minor),
  `rc-maint` (rc-style maintenance line for the currently-released minor), and `release` (stable);
  tags `vX.Y.Z` preserve historical release points across branch recreations.

  Rule: Create a new rc

    Scenario: Developer triggers rc from main when rc tracks the currently-released minor
      Given version.txt on `main` is "2.3.0-dev"
      And version.txt on `rc` is "2.2.3-rc"
      And version.txt on `release` is "2.2.2"
      When Developer triggers `rc` workflow manually
      Then `rc-maint` is force-pushed from the prior `rc` HEAD (snapshot of "2.2.3-rc")
      And `rc` is force-pushed from `main` HEAD with version.txt set to "2.3.0-rc"
      And version.txt on `main` is bumped to "2.4.0-dev"

    Scenario: Developer triggers the first rc (bootstrap)
      Given version.txt on `main` is "2.3.0-dev"
      And `rc` does not exist
      And `release` does not exist
      When Developer triggers `rc` workflow manually
      Then the `rc-maint` snapshot step is a no-op (no prior `rc` to capture)
      And `rc` is force-pushed from `main` HEAD with version.txt set to "2.3.0-rc"
      And version.txt on `main` is bumped to "2.4.0-dev"

  Rule: Create an initial release

    Scenario: Developer triggers initial release from rc
      Given version.txt on `rc` is "2.3.0-rc"
      And no `patch-*` branch exists
      And tag "v2.3.0" does not exist
      When Developer triggers `release` workflow manually
      Then `release` is force-pushed from `rc` with version.txt set to "2.3.0"
      And annotated tag "v2.3.0" is created on `release` HEAD
      And version.txt on `rc` is bumped to "2.3.1-rc"

    Scenario: Retry after partial failure is idempotent
      Given version.txt on `release` is already "2.3.0"
      And tag "v2.3.0" exists on `release` HEAD
      And version.txt on `rc` is "2.3.0-rc"
      When Developer triggers `release` workflow manually
      Then `release` is not force-pushed
      And tag "v2.3.0" is not recreated
      And version.txt on `rc` is bumped to "2.3.1-rc"

    Scenario: Aborts when a patch is in flight
      Given a `patch-2.2.5` branch exists
      When Developer triggers `release` workflow manually
      Then the workflow fails

    Scenario: Aborts when rc has non-zero patch
      Given version.txt on `rc` is "2.3.1-rc"
      When Developer triggers `release` workflow manually
      Then the workflow fails

    Scenario: Aborts when tag collides on a different commit
      Given version.txt on `rc` is "2.3.0-rc"
      And tag "v2.3.0" exists on a commit other than the prospective `release` HEAD
      When Developer triggers `release` workflow manually
      Then the workflow fails

  Rule: Patch flow

    Scenario: Initiate patch from rc when rc and release share major.minor
      Given version.txt on `rc` is "2.3.1-rc"
      And version.txt on `release` is "2.3.0"
      And no `patch-2.3.1` branch exists
      When Developer triggers `patch` workflow manually
      Then branch `patch-2.3.1` is created from `rc` with version.txt set to "2.3.1"
      And version.txt on `rc` is bumped to "2.3.2-rc"

    Scenario: Initiate patch from rc-maint when rc has moved to a different minor
      Given version.txt on `rc` is "2.4.0-rc"
      And version.txt on `rc-maint` is "2.3.1-rc"
      And version.txt on `release` is "2.3.0"
      And no `patch-2.3.1` branch exists
      When Developer triggers `patch` workflow manually
      Then branch `patch-2.3.1` is created from `rc-maint` with version.txt set to "2.3.1"
      And version.txt on `rc-maint` is bumped to "2.3.2-rc"
      And version.txt on `rc` is unchanged

    Scenario: Create patch by merging PR to release
      Given a PR from `patch-2.3.1` to `release` is open and validated
      When Developer accepts the PR
      Then `release` HEAD has version.txt "2.3.1"
      And lightweight tag "v2.3.1" is (re)created on the new `release` HEAD
      And branch `patch-2.3.1` is deleted

    Scenario Outline: Validate patch on PR creation
      Given a PR from `<patch_branch>` to `release` is created
      And version.txt on `release` is "<release_ver>"
      And version.txt on `<patch_branch>` is "<patch_ver>"
      When `validate_patch` workflow runs
      Then result is "<result>"
      Examples:
        | patch_branch | release_ver | patch_ver | result |
        | patch-2.3.1  | 2.3.0       | 2.3.1     | pass   |
        | patch-2.3.5  | 2.3.0       | 2.3.5     | fail   |
        | patch-2.4.1  | 2.3.0       | 2.4.1     | fail   |