# Context architecture: softeng

## Overview

All softeng actions follow a single uniform pattern. The `Engineer` triggers an action with a `u-keyword`, the `AI Agent` runs `softeng.sh` to get workflow instructions, reads/creates/updates artifact files, and runs shell commands. The result is reported back to the Engineer.

## Key flows

### Generic flow

All softeng actions follow the same pattern:

```mermaid
sequenceDiagram
    actor engineer as 👤Engineer
    participant ai_agent as ⚙️AI Agent
    participant softeng as ⚙️softeng.sh
    participant artifacts as 📁Artifacts

    engineer->>ai_agent: u-keyword [instructions, parameters]
    activate ai_agent
    ai_agent->>softeng: execute action command
    softeng-->>ai_agent: workflow instructions
    ai_agent->>artifacts: read/create/update
    deactivate ai_agent
    ai_agent-->>engineer: report result
```

### Examples

Non-exhaustive list of actions and their artifacts:

- uchange
  - dispatch: softeng.sh action uchange
  - input: change description, optional issue URL
  - output: Active Change Folder with change.md

- uarchive
  - dispatch: softeng.sh action uarchive
  - input: Active Change Folder or --all
  - output: Active Change Folder moved to changes/archive/
  