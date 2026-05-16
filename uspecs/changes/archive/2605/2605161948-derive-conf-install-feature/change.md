---
registered_at: 2026-05-16T19:29:55Z
change_id: 2605161929-derive-conf-install-feature
type: docs
scope: conf, dev
baseline: 8b3401fc0d8bf4a0a63ee21d73396c02f9f25327
archived_at: 2026-05-16T19:48:51Z
---

# Change request: Derive conf context install feature from sources

## Why

The `conf` context (defined in `uspecs/specs/prod/domain.md` as system lifecycle management and configuration) has no functional specifications, even though plugin install behavior is already implemented and surfaced to Engineers through the generated marketplace `README.md` install block. Adding Gherkin specs derived from the existing codebase makes the install contract verifiable and discoverable from the specs tree.

Verifying the spec against agent host documentation also surfaced a defect in `scripts/_lib/gen-uspecs-market.py`: `render_install_block` emits `<cli> plugin install ...` for all three agents, but Codex uses `codex plugin add <name>@<marketplace>` and `codex plugin marketplace upgrade <name>` (not `install` / `update`). The generated Codex marketplace README therefore tells users to run commands that do not exist.

## What

- Create a functional specification for plugin installation and update under `uspecs/specs/prod/conf/` derived from current sources:
  - Per-agent commands (Claude Code, Augment Code, Codex)
  - Stable vs development streams (different marketplace and plugin names)
  - Install and update (marketplace refresh) flows
- Fix the marketplace README generator and its e2e oracle so the generated Codex README emits the correct install command (`codex plugin add ...`) while leaving Claude Code and Augment Code unchanged

## Functional design

- [x] create: [conf/install.feature](../../../../specs/prod/conf/install.feature)
  - Feature specification for plugin installation and update: Engineer adds an agent marketplace, installs the uspecs plugin, and later refreshes the marketplace to pick up new versions; scenarios cover all three agents (Claude Code, Augment Code, Codex) for both stable and development streams, derived from `scripts/_lib/gen-uspecs-market.py` (`render_install_block`, `resolve_names`, `dev_market_name`) and `scripts/templates/README.md.tpl`, with per-agent install/refresh subcommands cross-checked against the official Claude Code, Augment Code, and Codex CLI docs

## Construction

- [x] update: [_lib/gen-uspecs-market.py](../../../../../scripts/_lib/gen-uspecs-market.py)
  - add: `install_verb` field to `AgentConfig` (`"install"` for claude/augment, `"add"` for codex)
  - update: `render_install_block` to emit `<cli> plugin <install_verb> <plugin>@<market>` so the generated Codex README uses `codex plugin add ...` instead of the non-existent `codex plugin install ...`

- [x] update: [e2e/helpers.bash](../../../../../tests/e2e/helpers.bash)
  - update: `_assert_dev_install_block` to expect `codex plugin add uspecs-dev@...` for the codex agent while keeping `plugin install` for claude and augment
