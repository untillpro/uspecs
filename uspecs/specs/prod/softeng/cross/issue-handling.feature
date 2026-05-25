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
# - [uchange.feature](../uchange.feature) -- Scenario: Agent is instructed to determine whether issue URL is fetchable
#   uchange action instructions tell the agent to pass --issue-url when user
#   input contains a URL and to also pass --fetchable when it can fetch the
#   issue body from that URL.
#
# - [uchange.feature](../uchange.feature) -- Scenario: Issue URL is fetchable
#   uchange records the issue URL in frontmatter, instructs the agent to
#   fetch the issue and save it to issue-{issue-number}.md, and change.md
#   begins with a Refs bulleted list whose entries have the form
#   [{issue-number}: {issue-title}](./issue-{issue-number}.md), followed by
#   ## Why and ## What (with conditional ## How per separate scenarios).
#
# - [uchange.feature](../uchange.feature) -- Scenario: Issue URL is not fetchable
#   uchange records the issue URL in frontmatter, emits no fetch instruction,
#   and change.md uses the ## Why + ## What shape.
#
# - [uchange.feature](../uchange.feature) -- Scenario: Why and What sourced from issue under --fetchable
#   ## Why and ## What are populated by distilling the fetched issue in
#   the change's terms, not by verbatim restatement; semantics and per-type
#   guidance for both sections are preserved from the non-fetchable shape.
#
# - [uchange.feature](../uchange.feature) -- Scenario Outline: ## How section under --fetchable
#   With --how, ## How is always produced. Without --how, ## How is
#   produced only when the fetched issue describes an approach/design.
#
# - [uchange.feature](../uchange.feature) -- Scenario: --fetchable without an issue URL
#   --fetchable requires an issue URL.
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
