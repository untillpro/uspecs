# Create change request file

## data

Create folder `${change_folder}` (its parent `uspecs/changes/` already exists).

Fetch the issue at ${issue_url} and save it to ${change_folder}/issue-{issue-number}.md following `@artdef_issue_file`. (?fetchable_maybe)

Create file `${change_file}` containing the verbatim contents of `@artifact_change_frontmatter`, then append the following sections:

- Change request, Why and What, see `@artdef_change_why_what`
- How, see `@artdef_change_how` (?how_maybe)
- How (emit only if the fetched issue contains information for the How section; omit otherwise), see `@artdef_change_how` (?fetchable_no_how_maybe)
`@include_impl_sections`

Run `git checkout -b ${branch_name}` (?create_branch)

Rules:

- Do not start implementation, only add sections as described above
