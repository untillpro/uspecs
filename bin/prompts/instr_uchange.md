# Create change request file

## data

Create folder `${change_folder}` (its parent `uspecs/changes/` already exists).

Create file `${change_file}` containing the verbatim contents of `@artifact_change_frontmatter`, then append the following sections:

- Change request, Why and What, see `@artdef_change_why_what`
- How, see `@artdef_change_how` (?no_impl)
`@include_impl_sections`

Run `git checkout -b ${branch_name}` (?create_branch)

Rules:

- Do not start implementation, only add sections as described above
