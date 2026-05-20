# Context architecture: softeng

## Overview

Most softeng actions follow a single uniform pattern. The `Engineer` triggers an action with a `u-keyword`, the `AI Agent` runs `softeng.sh` to get workflow instructions, reads/creates/updates artifact files, and runs shell commands. The result is reported back to the Engineer.

`uclarify` is the exception: it has no `softeng.sh` dispatch. The AI Agent reads the action body directly from `scripts/templates/actions/uclarify.md` (in installed plugins, the rendered command/skill) and executes its instructions.

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

### Self-review flow

`self-review` is a top-level softeng command (not an action). It is auto-invoked by the AI Agent at the end of a `uimpl` cycle that completed at least one to-do item, unless `--no-self-review` was passed to `uimpl`. Each stage prompt instructs the Agent to perform a scoped review, fix findings inline, and invoke the next stage. The chain ends with a results report to the Engineer.

```text
Engineer
  |
  v
uimpl  (processes todos)
  |
  +--(--no-self-review)--> stop
  |
  v
Construction todos completed?
  |
  +--(no, specs only)--> self-review --type specs --stage A
  |                         |
  |                         v
  |                       review + fix inline
  |                         |
  |                         v
  |                       report -> Engineer
  |
  +--(yes)--> evaluate concurrency
                |
                v
              self-review --type construction --stage A [--concurrency]
                |
                v
              review + fix inline
                |
                v
              self-review --type construction --stage B [--concurrency]
                |
                v
              review + fix inline
                |
                +--(no --concurrency)--> report -> Engineer
                |
                +--(--concurrency)--> self-review --type construction --stage C --concurrency
                                          |
                                          v
                                        review + fix inline
                                          |
                                          v
                                        report -> Engineer
```

Key artifacts:

- [bin/softeng.sh](../../../../bin/softeng.sh)
  - `cmd_self_review` dispatch; `cmd_action_uimpl` emits the chain instruction
- [bin/prompts/instr_uimpl_todos.md](../../../../bin/prompts/instr_uimpl_todos.md)
  - trailing chain hand-off appended after todos are completed
- [bin/prompts/instr_self_review_specs_a.md](../../../../bin/prompts/instr_self_review_specs_a.md)
  - specs Stage A (terminal)
- [bin/prompts/instr_self_review_construction_a.md](../../../../bin/prompts/instr_self_review_construction_a.md)
  - construction Stage A -> B
- [bin/prompts/instr_self_review_construction_b.md](../../../../bin/prompts/instr_self_review_construction_b.md)
  - construction Stage B (terminal unless `--concurrency`)
- [bin/prompts/instr_self_review_construction_c.md](../../../../bin/prompts/instr_self_review_construction_c.md)
  - construction Stage C, concurrency (terminal)
- [self-review.feature](self-review.feature)
  - functional design for the `self-review` command
- [uimpl.feature](uimpl.feature)
  - functional design for the uimpl auto-invoke scenarios

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
  