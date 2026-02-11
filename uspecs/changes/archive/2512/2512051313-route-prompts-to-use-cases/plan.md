# Implementation plan: Route prompts to use cases

Change: `[change.md](change.md)`

## Files modification

- [x] create: `[actions/register-base.md](../../../.uspecs/actions/register-base.md)`
  - Common flow: read specs-rules.md, create change folder, get baseline, create change.md
  - Accepts template parameter from calling action

- [x] create: `[actions/init-project.md](../../../.uspecs/actions/init-project.md)`
  - Trigger: "initialize project [name] [description]"
  - Validate: specs/ folder must not exist
  - Infer project name from current folder if not provided
  - Call register-base with change-init.md template

- [x] create: `[actions/config-td.md](../../../.uspecs/actions/config-td.md)`
  - Trigger: "configure technical design rules"
  - Validate: specs/td-rules.md must not exist
  - Call register-base with change-td.md template

- [x] create: `[actions/config-pd.md](../../../.uspecs/actions/config-pd.md)`
  - Trigger: "configure product design rules"
  - Validate: specs/fd-rules.md and specs/uxui-rules.md must not exist
  - Call register-base with change-pd.md template

- [x] update: `[actions/register.md](../../../.uspecs/actions/register.md)`
  - Remove routing table and validation logic
  - Call register-base with change-standard.md template

- [x] update: `[AGENTS.md](../../../AGENTS.md)`
  - Add triggering instruction for "initialize project"
  - Add triggering instruction for "configure technical design rules"
  - Add triggering instruction for "configure product design rules"
  