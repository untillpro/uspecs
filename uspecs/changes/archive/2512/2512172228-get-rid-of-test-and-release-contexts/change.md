# Change: Get rid of test and release contexts, merge into dev

- archived_at: 2025-12-17T21:47:36Z
- registered_at: 2025-12-17T21:27:07Z
- change_id: 251217-get-rid-of-test-and-release-contexts
- baseline: 0784323e042f3b5f89ec19f126ecdbf7767e6b62

## Problem

The current context structure includes separate test and release contexts that add unnecessary complexity. These contexts are not providing sufficient value to justify their maintenance overhead and cognitive load.

## Proposal

Consolidate test and release contexts into the dev context, simplifying the overall context structure and reducing maintenance burden while preserving essential functionality.

Scope:

- Merge test and release contexts into dev context
- Keep ops context separate (operations concerns remain distinct from development)
- Update all relationships involving test and release to reference dev instead
- All future devops specifications go into specs/devops/dev folder

Implementation details:

- Update dev context description to "Development, testing, and release automation"
- Update contexts.yml metadata to add modified_at field while preserving generated_at
- Regenerate domain-devops.md by running build-rels.sh after contexts.yml update
