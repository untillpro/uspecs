# Create change request file

## data

Create folder `${change_folder}` (its parent `uspecs/changes/` already exists).

Create file `${change_file}` containing the verbatim contents of `@artifact_change_frontmatter`, then append the following sections:

- Change request and Context section, see `@artdef_change_context` (?fetchable_maybe)
- Change request, Why and What, see `@artdef_change_why_what` (?!fetchable_maybe)
- How, see `@artdef_change_how` (?how_maybe)
`@include_impl_sections`

Fetch the issue at ${issue_url} and save it to ${change_folder}/issue.md following `@artdef_issue_file`. (?fetchable_maybe)

Run `git checkout -b ${branch_name}` (?create_branch)

Rules:

- Do not start implementation, only add sections as described above
