---
change_id: 2605231909-drop-unused-frontmatter-fields
type: refactor
scope: softeng
---

# Change request: Drop unused audit frontmatter fields

## Why

The `registered_at`, `baseline`, and `archived_at` frontmatter fields in `change.md` are written by `uchange` and `uarchive` but never read by any action. The original consumer of `baseline` was `usync`, which now computes its baseline live as `git merge-base` with the default branch, so the frontmatter value is dead metadata. The folder name already encodes registration time at minute precision, and the git history captures archival, making these audit-only fields redundant.

## What

No change to any externally observed behavior of `uchange`, `uarchive`, `upr`, `umergepr`, or `usync`. All fields that any action reads from frontmatter (`type`, `scope`, `breaking`, `issue_url`, `change_id`) remain unchanged, and the YAML frontmatter delimiter shape preserved by `upr` for PR bodies is unaffected. Behavior preserved: folder layout under `uspecs/changes/` and `uspecs/changes/archive/`, PR title and commit subject composition, archival move and link rewriting.

- Stop emitting `registered_at` and `baseline` in the frontmatter produced by `uchange`
- Stop emitting `archived_at` in the frontmatter mutated by `uarchive`

## How

Decisions:

- Remove the `registered_at` and `baseline` lines from the frontmatter string assembled in `cmd_action_uchange`, and delete the surrounding `get_timestamp` / `get_baseline` calls used solely for those values
- Remove the `archived_at` insertion `awk` pipeline in `cmd_action_uarchive`; the archive move alone is the audit trail
- Switch the `md_read_frontmatter_field` unit fixture to a field that still exists (e.g. `change_id`) so the helper coverage is preserved without resurrecting `registered_at`
- Update the sys-test fixtures and assertions that currently produce or check `registered_at` / `archived_at` lines to use the new minimal frontmatter shape

Out of scope:

- Rewriting frontmatter in already-archived change files under `uspecs/changes/archive/` (kept as historical record)
- Changes to fields read by any action (`type`, `scope`, `breaking`, `issue_url`, `change_id`)
- Reworking the PR-body YAML code-fence shape in `cmd_action_upr`

References:

- [uchange and uarchive in softeng.sh](../../../../../bin/softeng.sh)
- [uchange sys tests](../../../../../tests/sys/softeng.sh-action-uchange.bats)
- [upr sys tests with frontmatter fixtures](../../../../../tests/sys/softeng.sh-action-upr.bats)
- [umergepr sys tests with frontmatter fixture](../../../../../tests/sys/softeng.sh-action-umergepr.bats)
- [sys-test helpers writing frontmatter](../../../../../tests/sys/helpers.bash)
- [md_read_frontmatter_field unit test](../../../../../tests/unit/utils-md.bats)

## Construction

### Tests

- [x] update: [tests/unit/utils-md.bats](../../../../../tests/unit/utils-md.bats)
  - update: the `change.md` frontmatter fixture in `setup()` to drop the `registered_at` and `baseline` lines (keep `change_id` and `issue_url`)
  - remove: the `frontmatter: extracts timestamp field` test that exercises the helper against `registered_at` (the `change_id` and `issue_url` tests continue to cover the helper, including a value with colons)

- [x] update: [tests/sys/helpers.bash](../../../../../tests/sys/helpers.bash)
  - remove: the `"registered_at: 2026-01-01T00:00:00Z"` line from the change.md frontmatter fixture written by the shared helper

- [x] update: [tests/sys/softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - remove: the `_assert_frontmatter_contains "registered_at: "` and `_assert_frontmatter_contains "baseline: "` assertions in the "uchange: frontmatter artifact contains change_id" test
  - update: the `--no-impl` idempotency test's `sed` normalization to drop the `registered_at: [^[:space:]]+` substitution (folder-name `TIMESTAMP` substitution remains)
  - update: the comment above that normalization to mention only the timestamped folder name

- [x] update: [tests/sys/softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - remove: every `echo "registered_at: ..."` and `echo "archived_at: ..."` line from change.md frontmatter fixtures across the file (the archived-WCF test continues to signal archived state via folder location under `uspecs/changes/archive/`, so dropping `archived_at:` from its fixture does not weaken the assertion)

- [x] update: [tests/sys/softeng.sh-action-umergepr.bats](../../../../../tests/sys/softeng.sh-action-umergepr.bats)
  - remove: the `echo "registered_at: 2026-01-01T00:00:00Z"` line from the change.md frontmatter fixture

### Implementation

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: `cmd_action_uchange` -- drop the local `registered_at` and `baseline` variables, their assignments, and the corresponding `_fm+=...` lines from the frontmatter builder. The first emitted field becomes `change_id`
  - update: `cmd_action_uarchive` -- remove the `archived_at` insertion block (the `timestamp=$(get_timestamp)`, the `temp_create_file temp_file`, the `awk` pipeline that injects/strips `archived_at:`, and the `cat "$temp_file" > "$change_file"` write-back). The archive move is now the sole archival signal
  - remove: the `get_baseline` helper (no remaining callers after the `cmd_action_uchange` change)
  - remove: the `get_timestamp` helper (no remaining callers after the `cmd_action_uchange` and `cmd_action_uarchive` changes; re-verify with `rg "get_timestamp" bin/softeng.sh` before deletion)
