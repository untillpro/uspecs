---
registered_at: 2026-05-23T11:36:25Z
change_id: 2605231136-uversion-check-new-version
type: feat
scope: softeng
baseline: 3bc978131de1935e0f9656af0a82f9d8d4cc8b1a
archived_at: 2026-05-23T15:05:31Z
---

# Change request: uversion action checks for newer versions

## Why

Users running the uversion action can see the currently installed plugin version, but they still need a separate manual check to know whether an update is available. Adding update awareness makes the action more useful as a quick health check for the uspecs developer tooling.

## What

The uversion action will report both the current installed version and whether a newer version is available from the same per-agent plugin marketplace stream that supplied the installed plugin.

- Detect when the current stable installation is up to date by comparing against the latest stable version in the same marketplace.
- Detect when the current development installation is up to date by comparing against the latest development build in the same marketplace.
- Report the available version when a newer stable or development build can be installed.
- Report that availability is unknown when the version source cannot be checked, while still displaying the installed version.
- Treat source repository executions that report the sentinel version as local source builds and skip availability checking.
- Present the result in the normal uversion action output without installing, updating, or requiring a separate version-check command.

## How

Decisions:

- Keep `bin/softeng.sh` as the uversion dispatcher, and run the availability check through `bin/_lib/uversion.sh` as a separate shell helper.

- Hold the six `USPECS_*` metadata sentinels in a dedicated `bin/_lib/meta.sh` file sourced by both `bin/softeng.sh` and `bin/_lib/uversion.sh`, so the helper does not depend on inherited environment variables.

- Generate plugin-local marketplace metadata in `scripts/_lib/gen-uspecs-market.py` by rewriting the `USPECS_*` constants in the copied `bin/_lib/meta.sh`, next to the existing `USPECS_VERSION` rewrite.

  Stable Codex example:

  ```bash
  USPECS_VERSION="2.3.0"
  USPECS_MARKETPLACE_REPO="uspecs/uspecs-plugins-codex"
  USPECS_MARKETPLACE_NAME="uspecs-plugins-codex"
  USPECS_STREAM="stable"
  USPECS_CLI="codex"
  USPECS_MARKETPLACE_UPDATE_VERB="upgrade"
  ```

  Development Codex example:

  ```bash
  USPECS_VERSION="2.3.0-dev+20260504-1519.8da604592d28"
  USPECS_MARKETPLACE_REPO="uspecs/uspecs-dev-plugins-codex"
  USPECS_MARKETPLACE_NAME="uspecs-dev-plugins-codex"
  USPECS_STREAM="development"
  USPECS_CLI="codex"
  USPECS_MARKETPLACE_UPDATE_VERB="upgrade"
  ```

- Use `USPECS_MARKETPLACE_REPO` to fetch that repository's generated marketplace manifest directly. Treat `.claude-plugin/marketplace.json` `metadata.version` as the latest version for that stream.

- Keep per-agent marketplace update command differences in `AGENT_CONFIGS` as structured `AgentConfig` fields: `cli: str` and `marketplace_update_verb: str`; render the update command from those values.
  - Claude: `cli="claude"`, `marketplace_update_verb="update"`
  - Augment: `cli="auggie"`, `marketplace_update_verb="update"`
  - Codex: `cli="codex"`, `marketplace_update_verb="upgrade"`.

- Keep availability reporting best-effort: source sentinel builds skip the check, and metadata or marketplace failures report unknown availability.

- Update `bin/prompts/instr_uversion.md` to instruct the agent to show installed version, availability, and marketplace update guidance without executing commands.

Out of scope:

- Automatically installing or updating the uspecs plugin.
- Checking unrelated marketplace streams or switching between stable and development streams.

References:

- [uversion dispatcher](../../../../../bin/softeng.sh)
- [plugin metadata sentinels](../../../../../bin/_lib/meta.sh)
- [uversion helper](../../../../../bin/_lib/uversion.sh)
- [uversion prompt](../../../../../bin/prompts/instr_uversion.md)
- [marketplace generator](../../../../../scripts/_lib/gen-uspecs-market.py)
- [uversion system tests](../../../../../tests/sys/softeng.sh-action-uversion.bats)
- [marketplace delivery tests](../../../../../tests/e2e/deliver.bats)
- [recorded decisions](decisions.md)

## Functional design

- [x] update: [softeng/uversion.feature](../../../../specs/prod/softeng/uversion.feature)
  - update: "Display version" scenario outline to include update availability in the normal uversion action output
  - add: examples covering stable and development installations that are already up to date in their marketplace stream
  - add: examples covering stable and development installations where a newer version is available in their marketplace stream
  - add: scenario for unavailable marketplace checks that still displays the installed version with unknown availability
  - add: scenario for local source builds that skip availability checking
  - add: scenario coverage that uversion reports availability without installing, updating, or requiring a separate version-check command
  - add: scenario coverage that newer-version availability includes update instructions

## Construction

- [x] update: [softeng.sh-action-uversion.bats](../../../../../tests/sys/softeng.sh-action-uversion.bats)
  - add: source repository sentinel case asserts availability checking is skipped while the installed version is displayed
  - add: marketplace-backed stable and development cases covering up-to-date and newer-version availability output
  - add: unavailable metadata or marketplace fetch case asserting the installed version is still reported with unknown availability
  - assert: newer-version cases include update instructions but do not execute install/update commands or require a separate version-check command

- [x] update: [deliver.bats](../../../../../tests/e2e/deliver.bats)
  - add: stable and development marketplace generation assertions for generated `USPECS_*` constants in `bin/_lib/meta.sh`
  - assert: generated constants include `USPECS_MARKETPLACE_REPO`, `USPECS_MARKETPLACE_NAME`, `USPECS_STREAM`, `USPECS_CLI`, and `USPECS_MARKETPLACE_UPDATE_VERB`

- [x] update: [e2e/helpers.bash](../../../../../tests/e2e/helpers.bash)
  - update: `_softeng_version` reads `USPECS_VERSION` from `bin/_lib/meta.sh` in the delivered plugin folder

- [x] update: [gen-uspecs-market.py](../../../../../scripts/_lib/gen-uspecs-market.py)
  - add: `marketplace_update_verb: str` to `AgentConfig`
  - add: per-agent values: Claude and Augment use `update`; Codex uses `upgrade`
  - generate: `USPECS_*` constants in the copied `bin/_lib/meta.sh`
  - preserve: existing `USPECS_VERSION` rewriting, retargeted to `bin/_lib/meta.sh`

- [x] create: [_lib/meta.sh](../../../../../bin/_lib/meta.sh)
  - add: the six `USPECS_*` metadata sentinels as a single sourceable file consumed by `bin/softeng.sh` and `bin/_lib/uversion.sh`
  - omit: `export` keywords (the file is sourced, not inherited via env)

- [x] update: [softeng.sh](../../../../../bin/softeng.sh)
  - replace: inline `USPECS_*` definitions with `source` of `bin/_lib/meta.sh`
  - add: invoke `bin/_lib/uversion.sh` as a separate shell to collect availability fields
  - preserve: existing unknown-argument rejection and source repository sentinel version output

- [x] create: [_lib/uversion.sh](../../../../../bin/_lib/uversion.sh)
  - add: `source` of sibling `bin/_lib/meta.sh` so the helper sees `USPECS_*` directly
  - add: source sentinel detection and generated `USPECS_*` metadata checks
  - add: best-effort latest-version lookup using `USPECS_MARKETPLACE_REPO` and `.claude-plugin/marketplace.json` `metadata.version`
  - add: stable semantic-version comparison and development build timestamp comparison
  - output: shell-escaped availability fields for `softeng.sh`, using `availability_note` for the inconclusive-state explanation

- [x] update: [prompts/instr_uversion.md](../../../../../bin/prompts/instr_uversion.md)
  - update: instructions to display installed version plus update availability
  - add: marketplace update instruction when a newer version is available, rendered from `USPECS_CLI`, `USPECS_MARKETPLACE_UPDATE_VERB`, and `USPECS_MARKETPLACE_NAME`
  - add: source sentinel behavior that skips availability checking
  - add: availability note line, gated on `availability_note`, that surfaces why availability is `skipped` or `unknown`
  - assert: do not execute commands or require a separate version-check command

## Quick start

Show the installed plugin version and update availability:

```bash
bash bin/softeng.sh action uversion
```
