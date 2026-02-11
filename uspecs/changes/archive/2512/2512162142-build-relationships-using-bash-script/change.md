# Change: Build relationships using bash script

- archived_at: 2025-12-16T21:56:50Z
- registered_at: 2025-12-16T20:30:17Z
- change_id: 251216-build-relationships-using-bash-script
- baseline: a37428fa88312fa9d82913ef54969a843ad28f50

## Problem

The current "build relationships" action is implemented as a prompt-based workflow in build-relationships.md, requiring the AI agent to manually read configuration, parse contexts, and generate relationship diagrams. This approach is error-prone and inconsistent.

## Proposal

Replace the prompt-based workflow with a bash script that automates the relationship diagram generation process. The script will read contexts.yml, parse relationships, and generate relationship diagram files following the existing template structure.

## Principles

- main.md calls uspecs.sh
- uspecs.sh calls build-rels.sh
- build-rels.sh creates domain-{context-name}.md per domain in contexts.yml
  - [example-context.md](example-context.md)
  - diagrams as in [build-relationships.md](../../u/build-relationships.md)
- we do not need build-relationships.md anymore

## Decisions
