---
registered_at: 2026-05-21T14:21:40Z
change_id: 2605211421-consolidate-action-options
type: refactor
scope: softeng, dev
baseline: 83b7818ef7acac9f6772628d081a36f5653224e6
archived_at: 2026-05-21T17:35:07Z
---

# Change request: Consolidate action options to a single source of truth

## Why

The CLI option list for each `softeng action <name>` lives in four places:

- the option parser inside `bin/softeng.sh`
- the usage header comment near the top of `softeng.sh`
- the option-signature line(s) in the header comment above each `cmd_action_*` function in `softeng.sh`
- the `options:` field in `scripts/templates/actions/<name>.yaml`

These surfaces drifted in practice: `uimpl.yaml` advertises only `--change-folder` while the parser also accepts `--plan` and `--no-self-review`, so agents installed from the marketplace cannot discover the missing flags. The shape that allowed this drift is the duplication itself - tests and reviewer guidance can close the gap reactively, but a single source of truth removes the failure mode at its root.

## What

Refactor with no behavior change to the dispatched actions. The invariant preserved is the rendered `Options: ...` line in each generated command/skill, for every agent (claude, augment, codex), for every existing action.

Delivered together so the change is self-protecting:

- Per-action option metadata held as a bash data structure inside `bin/softeng.sh` (one table per action), exposed via a new `softeng meta options <action>` subcommand. Each `cmd_action_*` keeps its hand-written `case`-arm parser; the table is co-declared in the same file and asserted to match the parser by the consistency test below. The marketplace generator reads `meta options` instead of duplicating option lists, and the `options:` field is removed from `scripts/templates/actions/*.yaml`.

- Both in-script documentation surfaces are removed: the top-of-file `Usage:` block in `softeng.sh` and the option-signature line(s) in the header comment above each `cmd_action_*` function. `softeng.sh` is an internal script with no `--help` flag and no runtime reader of either surface; behavior of each option is already exhaustively specified in the corresponding `*.feature` file, and `softeng meta options <action>` is the discoverable runtime source. Prose in the per-function headers that describes implementation-level side effects or contracts not covered by scenarios (e.g. "side-effect-free with respect to the Change Folder", "`<type>` is not validated") is preserved.

- A consistency test that fails when the runtime flag parser inside any `cmd_action_*` and that action's option table disagree, so a hand-edited parser arm or a stale table entry cannot drift silently in CI.

- A reviewer skill that fires on edits to the per-action option tables and to `cmd_action_*` parsers, directing the author to keep the table and the parser arms aligned and pointing at the consistency test.

## How

Not needed.

## Functional design

Not needed.

## Construction

Tests:

- [x] create: [softeng.sh-meta-options.bats](../../../../../tests/sys/softeng.sh-meta-options.bats)
  - Bats system test for the new `softeng meta options <action>` subcommand and the option-table <->parser consistency invariant
  - Cases:
    - For every dispatched action (`uchange`, `uimpl`, `uarchive`, `upr`, `umergepr`, `usync`, `uversion`): `softeng meta options <action>` exits 0 and prints the action's option list
    - `softeng meta options <unknown-action>` exits non-zero with a clear error
    - Consistency: for every dispatched action, the set of flags reported by `softeng meta options <action>` equals the set of flags accepted by the corresponding `cmd_action_*` `case` arms, using the parser-helper output below; fails if any flag is in one but not the other

- [x] create: [parse-softeng-action-options.py](../../../../../tests/sys/parse-softeng-action-options.py)
  - Python helper that reads `bin/softeng.sh` and extracts the literal option flags accepted by each `cmd_action_*` argument parser, including long options and supported short options such as `-y`
  - Scope the parser intentionally to the local script shape: find each `cmd_action_<action>()` function, locate the option-parsing `case` arm, and return literal flag arms only
  - Emit a stable machine-readable format suitable for Bats assertions, e.g. one line per action: `<action>\t<option> <option> ...`
  - Fail with a clear error if an expected action parser cannot be found, or if the parser shape changes beyond the helper's supported pattern

Source script:

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - add: per-action option table data structure (one entry per dispatched action: `uchange`, `uimpl`, `uarchive`, `upr`, `umergepr`, `usync`, `uversion`), co-declared next to or referenced from each `cmd_action_*` function
  - add: `softeng meta options <action>` subcommand that prints the action's option list (the existing rendered `Options: ...` line shape) from the table, and errors on unknown actions
  - remove: top-of-file `Usage:` block (lines covering `softeng action ...`, `softeng change ...`, `softeng diff ...`, `softeng self-review ...`)
  - remove: option-signature line(s) in the header comment above each `cmd_action_*` function; preserve prose describing implementation-level side effects or contracts not covered by `*.feature` scenarios

Action templates:

- [x] update: [actions/uchange.yaml](../../../../../scripts/templates/actions/uchange.yaml): remove `options:` field
- [x] update: [actions/uimpl.yaml](../../../../../scripts/templates/actions/uimpl.yaml): remove `options:` field
- [x] update: [actions/uarchive.yaml](../../../../../scripts/templates/actions/uarchive.yaml): remove `options:` field
- [x] update: [actions/upr.yaml](../../../../../scripts/templates/actions/upr.yaml): remove `options:` field
- [x] update: [actions/usync.yaml](../../../../../scripts/templates/actions/usync.yaml): remove `options:` field

Marketplace generator:

- [x] update: [_lib/gen-uspecs-market.py](../../../../../scripts/_lib/gen-uspecs-market.py)
  - update: replace YAML-derived `options` loading with a call to `softeng meta options <action>` for each action; preserve the existing rendered `Options: ...` line shape for every agent (`claude`, `augment`, `codex`)
  - remove: `options: str = ""` field on `ActionData` and the `options=data.get("options", "")` initialization (or keep `ActionData.options` populated from the new source — whichever keeps the diff smaller while preserving the rendered output byte-for-byte)

Reviewer skill:

- [x] create: [skills/softeng-action-options/SKILL.md](../../../../../.claude/skills/softeng-action-options/SKILL.md)
  - Reviewer skill that fires on edits to the per-action option tables in `bin/softeng.sh` and to `cmd_action_*` parser `case` arms
  - Directs the author to keep the option table and the parser arms aligned for the action being edited
  - Points at `tests/sys/softeng.sh-meta-options.bats` as the consistency check to run locally
