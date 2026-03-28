---
registered_at: 2026-03-28T15:09:30Z
change_id: 2603281509-upr-archive-wcf-default
baseline: a32ee1834a2182d0c5cf2a06760f9fb8d4ddcd04
archived_at: 2026-03-28T15:48:57Z
---

# Change request: Archive WCF by default in upr action

## Why

The upr action currently leaves the Working Change Folder (WCF) active after creating a PR. The umergepr action archives it later during merge. Archiving at PR creation time keeps the changes folder clean and consistent with the PR workflow.

## What

The upr action archives the WCF by default before squashing and pushing:

- Archive active WCF (same logic as umergepr) before the squash/push step
- Add --no-archive flag to skip archiving when explicitly requested
- When WCF is already archived, skip archiving
