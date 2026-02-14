---
registered_at: 2026-02-14T17:49:00Z
change_id: 2602141749-engineer-install-update-upgrade
baseline: 967257e2d86e4520b48e69d6300c603db359689b
---

# Change request: Engineer manages uspecs per project

## Why

Engineers need a way, per project:

- install uspecs for natural language invocation method
  - later install uspecs for agent-specific commands invocation method
- update to the latest minor version
- upgrade to the latest major version
- configure invocation method (natural language, agent-specific commands)

## What

- README.md contains a link to installer like:

```text
curl -fsSL https://raw.githubusercontent.com/untillpro/uspecs/main/scripts/manage.sh | bash -s install --project <project-name>
```

