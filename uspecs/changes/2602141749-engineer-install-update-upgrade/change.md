---
registered_at: 2026-02-14T17:49:00Z
change_id: 2602141749-engineer-install-update-upgrade
baseline: 967257e2d86e4520b48e69d6300c603db359689b
---

# Change request: Engineer installs, updates and upgrades uspecs

## Why

Engineers need standardized commands to install uspecs into new projects, update to the latest version from the home repository, and upgrade when the framework structure or tooling changes.

## What

Add install, update, and upgrade operations to uspecs tooling:

- Install operation copies uspecs framework into a new project and initializes directory structure
- Update operation fetches latest changes from home repository while preserving project customizations
- Upgrade operation applies migration scripts when framework structure changes

Scripts and documentation:

- uspecs/u/scripts/install.sh - installation logic
- uspecs/u/scripts/update.sh - update logic
- uspecs/u/scripts/upgrade.sh - upgrade logic
- uspecs/u/actn-uchange.md - updated action definition
- uspecs/u/conf.md - version tracking configuration

