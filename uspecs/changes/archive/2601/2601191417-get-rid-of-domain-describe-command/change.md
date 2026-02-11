---
uspecs.registered_at: 2026-01-19T14:17:23Z
uspecs.change_id: 260119-get-rid-of-domain-describe-command
uspecs.baseline: b0c18e8c1a5e8efc55870dde9c92e9b728d6424c
uspecs.archived_at: 2026-01-19T14:21:32Z
---

# Change: Get rid of domain describe command

## Problem

The `uspecs domain describe` command exists in the uspecs.sh script but is no longer needed. This command was designed to generate domain-{domain-name}.md files from domains.yml, but this functionality is not currently being used in the project.

## Solution

Remove the domain describe command and all associated scripts from the uspecs tooling. This includes:

- Remove domain describe subcommand from uspecs.sh
- Delete domain-describe.sh script
- Delete domain-describe-yq.sh script  
- Delete domain-describe-fb.sh script
