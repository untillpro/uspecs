# Change: Remove config-td action

- Type: refactoring

## Problem

The config-td.md action is no longer needed as technical design configuration should be handled differently.

## Proposal

Remove the config-td.md action entirely. No replacement - functionality is being removed.

Files to delete:

- `.uspecs/actions/config-td.md`
- `.uspecs/templates/change-td.md`

Files to modify:

- `AGENTS.md` - remove trigger entry for "configure technical design rules"
- `.uspecs/actions/analyze-spec-impact.md` - remove config-td references
- `.uspecs/actions/plan.md` - remove "For config-td changes" section
- `.uspecs/templates/change-common-metadata.md` - remove config-td from Type values
- `docs/overview.md` - remove "Configure technical design rules" section

## Inferred requirements

- No orphan references should remain after removal
- Triggering instructions table should be updated
- All references to config-td in action files and templates should be cleaned up
