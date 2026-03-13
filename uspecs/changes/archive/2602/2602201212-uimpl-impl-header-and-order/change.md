---
registered_at: 2026-02-20T11:56:33Z
change_id: 2602201156-uimpl-impl-header-and-order
baseline: 9615f8c4debf4ae39bd9e13a19f81b2afd898372
archived_at: 2026-02-20T12:12:36Z
---

# Change request: Uimpl impl.md header and section order

## Why

The `uimpl` action has two defects in how it generates `impl.md`: it omits the required level-1 header, and it sometimes creates sections in the wrong order (e.g., Technical design before Functional design).

## What

Create `tmpl-impl.md` following the pattern of existing templates (`tmpl-change.md`, `tmpl-fd.md`, `tmpl-td.md`):

- Define the level-1 header format: `# Implementation plan: {Change request title}`
- Define the mandatory section order: Functional design, Provisioning and configuration, Technical design, Construction
- Move `## Structures` content from `actn-uimpl.md` into `tmpl-impl.md`

Update `actn-uimpl.md` to reference `$templates_folder/tmpl-impl.md` instead of the inline Structures section.
