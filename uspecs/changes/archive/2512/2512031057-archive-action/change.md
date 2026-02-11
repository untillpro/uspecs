# Change: Archive action should embrace all links into backticks

- Type: behavior
- Baseline: 8b5f2434486a9e75cfe6c540cea1769ae0f8e844

## Problem

When changes are archived (moved from changes/active/ to changes/archive/), the links in markdown files remain as active markdown links. These links can become obsolete over time as the referenced files may be moved, deleted, or restructured, making the archived documentation harder to understand.

## Proposal

Create an archive action that moves changes from changes/active/ to changes/archive/ and automatically converts all markdown links to backtick-wrapped text to preserve the link information while indicating they are historical references. Agents should use sed directly for efficient batch processing of link conversion.

## Inferred requirements

- Archive action should move change folders from changes/active/ to changes/archive/
- Convert links in ALL markdown files within the change folder (not just spec-impact.md and plan.md)
- Link conversion format: entire link wrapped in backticks: `` `[text](url)` ``
- Skip links that are already wrapped in backticks (don't double-wrap)
- Convert ALL links regardless of checkbox state
- Agents should use sed directly if available on the system
- If sed is not available, agents should use alternative text processing approach
- Trigger phrase: "Archive change"
- The action should be documented in .uspecs/actions/archive.md
- The action should be added to AGENTS.md triggering instructions with phrase "Archive change"
