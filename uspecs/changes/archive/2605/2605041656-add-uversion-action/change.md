---
registered_at: 2026-05-04T15:19:17Z
change_id: 2605041519-add-uversion-action
baseline: 8da604592d283b34924e33674083c4102038529b
archived_at: 2026-05-04T16:56:10Z
---

# Change request: Add uversion action

## Why

Users of the plugin need a quick way to see the version string that the marketplace generator (`gen-uspecs-market.py`) would receive for the current working tree.

## What

Introduce a new softeng action `uversion` that prints the marketplace version string for the current repo state.

## How

- New feature spec `uspecs/specs/prod/softeng/uversion.feature` describing the user-visible behavior of the action
- New action definition `scripts/templates/actions/uversion.yaml` so the marketplace generator surfaces `uversion` as a command/skill
- Declare a sentinel `USPECS_VERSION="0.0.0-source"` line near the top of `bin/softeng.sh`; in the source repo this value is printed as-is
- In `scripts/_lib/gen-uspecs-market.py`, after copying `bin/` into the plugin, rewrite the `USPECS_VERSION=...` line in the plugin copy of `softeng.sh` using `re.sub(r'^USPECS_VERSION=.*$', f'USPECS_VERSION="{version}"', text, count=1, flags=re.MULTILINE)` with the version supplied via `--version`
- Add `cmd_action_uversion` in `bin/softeng.sh` wired into the existing `action` dispatcher next to `uchange`, `uimpl`, `usync`, etc; it passes `$USPECS_VERSION` as a context variable to `emit_prompt` and uses a new template `bin/prompts/instr_uversion.md` whose `## data` section says "Display the uspecs framework plugin version to the user: ${version}"
- Register `uversion` in the "Available commands" line of the `<!-- uspecs:begin -->` block in `AGENTS.md` and `CLAUDE.md`

References:

- [bin/softeng.sh](../../../../../bin/softeng.sh)
- [scripts/_lib/gen-uspecs-market.py](../../../../../scripts/_lib/gen-uspecs-market.py)
- [scripts/deliver.sh](../../../../../scripts/deliver.sh)
- [AGENTS.md](../../../../../AGENTS.md)
- [CLAUDE.md](../../../../../CLAUDE.md)

## Functional design

- [x] create: [softeng/uversion.feature](../../../../specs/prod/softeng/uversion.feature)
  - Feature specification for the uversion action describing how the agent shows the plugin version

## Technical design

- [x] update: [softeng/arch.md](../../../../specs/prod/softeng/arch.md)
  - add: `uversion` entry in the actions list with dispatch `softeng.sh action uversion`, input "none", output "plugin version displayed to Engineer"

## Construction

- [x] create: [tests/sys/softeng.sh-action-uversion.bats](../../../../../tests/sys/softeng.sh-action-uversion.bats)
  - Bats system test for the uversion action
  - Asserts output contains `<LOG>`, `<AGENT_INSTRUCTIONS>`, `instr_uversion`, and the sentinel `0.0.0-source` when run from the source repo

- [x] update: [tests/e2e/deliver.bats](../../../../../tests/e2e/deliver.bats)
  - add: assertion that the generated plugin's `bin/softeng.sh` contains `USPECS_VERSION="<delivered_version>"` (sentinel substituted)

- [x] create: [scripts/templates/actions/uversion.yaml](../../../../../scripts/templates/actions/uversion.yaml)
  - Action definition consumed by `load_actions()` in `gen-uspecs-market.py`
  - Fields: `action: uversion`, `raw_text` instructing the agent to dispatch via `{{dispatch}}` and follow output instructions, no `options`

- [x] create: [bin/prompts/instr_uversion.md](../../../../../bin/prompts/instr_uversion.md)
  - Prompt template emitted by `cmd_action_uversion`
  - `## data` section: "Display the uspecs framework plugin version to the user: ${version}"

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - add: `USPECS_VERSION="0.0.0-source"` sentinel declaration near the top (after `set -Eeuo pipefail`)
  - add: `cmd_action_uversion()` function that resolves `prompts_dir`, emits log start, declares `version_vars=([version]="$USPECS_VERSION")`, and calls `emit_prompt "$prompts_dir" "instr_uversion" version_vars` after `prompt_start_instructions "results"`
  - update: `action` dispatcher case to route `uversion` to `cmd_action_uversion`
  - update: dispatcher error message to include `uversion` in the available actions list

- [x] update: [scripts/_lib/gen-uspecs-market.py](../../../../../scripts/_lib/gen-uspecs-market.py)
  - add: after `shutil.copytree(source / "bin", plugin_dir / "bin")`, read the copied `bin/softeng.sh`, apply `re.sub(r'^USPECS_VERSION=.*$', f'USPECS_VERSION="{version}"', text, count=1, flags=re.MULTILINE)`, write back

- [x] update: [AGENTS.md](../../../../../AGENTS.md)
  - update: "Available commands" line in the `<!-- uspecs:begin -->` block to include `uversion`

- [x] update: [CLAUDE.md](../../../../../CLAUDE.md)
  - update: "Available commands" line in the `<!-- uspecs:begin -->` block to include `uversion`

## Quick start

Show the plugin version:

```bash
bash bin/softeng.sh action uversion
```

In the source repository the emitted prompt carries `0.0.0-source`. In a generated marketplace plugin it carries the version supplied to `gen-uspecs-market.py --version`.
