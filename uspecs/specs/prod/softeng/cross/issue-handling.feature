Feature: Issue handling (cross-action)
Cross-reference hub for issue handling across softeng actions.

# Issue handling is a cross-action concept: a change request may reference
# an external issue URL, and downstream actions derive behaviour from it.
# This feature has no scenarios of its own -- each scenario lives in its
# natural home feature. Update this hub when adding or renaming any
# scenario listed below.
#
# ## Scenarios across features
#
# - [uchange.feature](../uchange.feature) -- Scenario Outline: Issue reference provided
#   uchange records the issue URL in frontmatter; with --fetchable the agent
#   is instructed to create issue.md and change.md uses the ## Context shape;
#   without --fetchable no fetch instruction is emitted and change.md uses
#   the ## Why + ## What shape.
#
# - [uchange.feature](../uchange.feature) -- Scenario: --fetchable without an issue reference
#   --fetchable requires an issue reference.
#
# - [uchange.feature](../uchange.feature) -- Scenario Outline: Issue reference: branch naming
#   Git branch name is derived from the issue id and the change name.
#
# - [upr.feature](../upr.feature) -- Scenario Outline: Construct PR title and commit message
#   When the change has an issue_url, the commit subject includes
#   `[<issue_id>]` and the commit body appends `Closes #<issue_id>`.
#
# - [upr.feature](../upr.feature) -- Scenario Outline: Construct PR body
#   When change.md uses the ## Context shape (issue case, --fetchable),
#   pr_body includes the ## Context section instead of ## Why and ## What.
#
# - [usync.feature](../usync.feature) -- Scenario: Core output
#   When issue.md exists, the Engineer is informed of any discrepancies
#   between issue.md and actual sources.
