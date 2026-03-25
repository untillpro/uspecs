---
registered_at: 2026-03-25T16:18:39Z
change_id: 2603251618-rename-uaccept-umergepr
baseline: c193fa970552d2b325b8f2440423ea363d619615
archived_at: 2026-03-25T17:59:14Z
---

# Change request: Rename uaccept to umergepr

## Why

The name `uaccept` is ambiguous - it reads as "accept the PR" which is what a reviewer does during approval, not what the author does after approval. `umergepr` unambiguously names the author's action and pairs naturally with `upr`.

## What

Rename the `uaccept` action keyword to `umergepr` across all files:

- `uspecs/u/scripts/uspecs.sh`: rename action keyword, function name `cmd_action_uaccept`, and all internal references
- `uspecs/u/scripts/prompts.md`: rename all `uaccept_*` section identifiers and occurrences of `uaccept` in prose
