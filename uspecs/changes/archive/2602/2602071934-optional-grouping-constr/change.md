---
registered_at: 2026-02-07T19:22:22Z
change_id: 2602072022-optional-grouping-constr
baseline: 96572b741237d25b0f236ac7c75a9bcbaa9ca90c
archived_at: 2026-02-07T19:34:30Z
---

# Change request: Add optional grouping to Construction section

## Why

When a Construction section in impl.md has many items spanning different categories, the flat list becomes hard to scan. Optional grouping under sub-headers would improve readability.

## What

Add optional `###` grouping support to the Construction section definition in `uspecs/u/actn-impl.md`:

- Update the Construction section rules/example to show that items can optionally be grouped under `###` headers (e.g., `### Schema changes`, `### Function signature changes`) when the list is long or spans multiple categories
