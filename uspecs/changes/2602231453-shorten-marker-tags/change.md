---
registered_at: 2026-02-23T14:53:38Z
change_id: 2602231453-shorten-marker-tags
baseline: 57afe0ebdb3e18f067af09eba61c3516ad598802
---

# Change request: Shorten uspecs marker tags

## Why

The current NLI injection markers `<!-- uspecs:triggering_instructions:begin -->` / `<!-- uspecs:triggering_instructions:end -->` are verbose. Shortening them to `<!-- uspecs:begin -->` / `<!-- uspecs:end -->` improves readability and reduces clutter in agent instruction files.

## What

Replace the marker tags used for NLI instruction injection:

- New markers: `<!-- uspecs:begin -->` and `<!-- uspecs:end -->`
- Old markers (`<!-- uspecs:triggering_instructions:begin/end -->`) are still recognized for backward compatibility
- When old markers are encountered during inject/remove operations, they are automatically upgraded to the new format
