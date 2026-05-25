Feature: Issue handling (cross-action)
Cross-reference hub for issue handling across softeng actions.

# Issue handling is a cross-action concept: a change request may include an
# external issue URL, and downstream actions derive behaviour from it.
# This feature has no scenarios of its own -- each scenario lives in its
# natural home feature. Update this hub when adding or renaming any
# scenario listed below.
#
# ## Scenarios across features
#
# - [uchange.feature](../uchange.feature) -- Rule: Handling issue URLs
#   uchange action instructions tell the agent to pass --issue-url when user
#   input contains a URL and to also pass --fetchable when it can fetch the
#   issue body. With --fetchable, change.md uses Refs + Why/What distilled
#   from the fetched issue, with conditional How; without --fetchable, no
#   fetch instruction is emitted and change.md uses the Why + What shape.
#
# - [uchange.feature](../uchange.feature) -- Scenario Outline: Issue URL: branch naming
#   Git branch name is derived from the issue id and the change name.
#
# - [upr.feature](../upr.feature) -- Scenario Outline: Construct PR title and commit message
#   When the change has an issue_url, the commit subject includes
#   `[<issue_id>]` and the commit body appends `Closes #<issue_id>`.
#
# - [upr.feature](../upr.feature) -- Scenario Outline: Construct PR body
#   When change.md uses the legacy ## Context shape (archived --fetchable
#   changes pre-dating the Refs + Why/What/How shape), pr_body includes the
#   ## Context section instead of ## Why and ## What.
#
# - [usync.feature](../usync.feature) -- Scenario: Core output
#   When an issue-{issue-number}.md file exists in the Change Folder, the
#   Engineer is informed of any discrepancies between it and actual sources.
