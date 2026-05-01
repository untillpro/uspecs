---
registered_at: 2026-04-28T15:19:17Z
change_id: 2604281519-add-artifact-emission-type
baseline: a2a8247694f304f44c6cec6f8df96b03dc473965
archived_at: 2026-04-28T18:04:41Z
---

# Change request: Introduce artifact emission type for opaque payloads

## Why

The `usync` git diff and changed-file list are free-form, opaque payloads, but they are currently routed through the templated `artdef` pipeline via `${diff}` and `${file_list}` substitution into `bin/prompts/artdef_usync_diff.md` and `bin/prompts/artdef_usync_file_list.md`. Recent engine fixes hardened the templating pipeline against literals inside substituted values (filter -> dep-scan -> substitute, with the unbound check and dep scan running on the pre-substitution body), but the underlying mismatch remains: `artdef` is meant for templated reusable fragments with dependencies and conditionals, not for opaque blobs.

## What

Introduce a new emission type `artifact`, parallel to `artdef`, that carries raw payloads end-to-end without any template processing, and migrate the `usync` diff and file-list flow onto it.

- New emission type `artifact` with contract: opaque payload in, escaped payload out -- no conditional filtering, no unbound-variable check, no `${VAR}` substitution, no `@artdef_*` dep scan
- Tag shape `<artifact id="..." descr="...">escaped_payload</artifact>` -- a fixed, deterministic tag with no random suffix
- Payload escape: XML entity encoding applied to the payload before rendering -- `&` -> `&amp;` (first), then `<` -> `&lt;`, then `>` -> `&gt;`. This guarantees the payload contains no `<` or `>` characters, so it cannot collide with the artifact's own closing tag and cannot be mistaken for nested structure by an agent reader. LLM consumers decode the entities reflexively
- Authoring API `emit_artifact <id> <payload> [descr]` in `bin/_lib/utils.sh`, queue-driven and rendered by the existing `emit_prompt` flush loop; no `.md` template file exists for an artifact
- Reference syntax `` `@artifact_<id>` `` in instructions, parallel to `` `@artdef_<id>` ``, prose-only (no dep resolution); the artifact is queued by the caller before `emit_prompt`
- Emission order: artifacts emitted before the root instruction, parallel to artdefs
- Migration: `usync` switches from `${diff}`/`${file_list}` substitution into artdef templates to `emit_artifact` calls; the two `artdef_usync_*.md` files are removed
- Test coverage: system test asserts the new tag shape; unit tests cover raw round-trip, entity-escape correctness, and a payload containing literal `<`, `>`, and `&` characters

## How

Emission flow (all `emit_*` functions, before and after this change):

```text
public API
----------

  emit_artifact <id> <payload> [descr]                           (NEW)
    -> push (artifact, id, descr, payload) to _EMIT_QUEUE

  emit_prompt <prompts_dir> <root_id> [vars_map_name]
    -> reset _EMIT_SEEN (dedup is per-walk; _EMIT_QUEUE is preserved
       so artifacts queued before this call survive into flush)
    -> _emit_collect <dir> <root_id> [vars]   (recursive, depth-first,
       |                                       deduped via _EMIT_SEEN)
       |
       |  for each `<dir>/<id>.md`:
       |    descr from first `# heading`; body after `## data`
       |
       |    _emit_filter_body
       |      drop lines ending with `(?var)` / `(?!var)` per vars map;
       |      error on unbound `${KEY}` placeholder
       |
       |    scan filtered body for `` `@artdef_<dep>` `` tokens;
       |    recurse _emit_collect for each dep
       |
       |    _emit_substitute_body
       |      replace `${KEY}` with vars[KEY]
       |
       |    push (artdef | instruction, id, descr, body) to _EMIT_QUEUE
       |    (tag = artdef if id matches `artdef_*` else instruction)
       v
    flush _EMIT_QUEUE (artdef deps first, root instruction last;
                       artifacts in caller order):
      tag=artdef      -> <artdef id="..." descr="...">body</artdef>
      tag=instruction -> <instruction id="..." descr="...">body</instruction>
      tag=artifact    -> _emit_xml_escape(payload)                   (NEW)
                           &  -> &amp;  (first)
                           <  -> &lt;
                           >  -> &gt;
                         -> <artifact id="..." descr="...">
                            escaped_payload</artifact>
```

Example -- `cmd_action_usync` after migration (small diff, change folder has `impl.md`, no `issue.md`):

```bash
emit_artifact "usync_diff"      "$diff_content"      "Diff since baseline"
emit_artifact "usync_file_list" "$file_list_content" "Changed files since baseline"

declare -A usync_vars=(
    [change_folder]="uspecs/changes/2604281519-add-artifact-emission-type"
    [specs_folder]="uspecs/specs"
    [impl_exists]="1"
    [issue_exists]=""
    [is_large_diff]=""
    [softeng_sh]="bin/softeng.sh"
)
emit_prompt "$prompts_dir" "instr_usync" usync_vars
```

Resulting output stream (note the entity-escaped `<`, `>`, `&` inside the diff payload):

```text
<artifact id="usync_diff" descr="Diff since baseline">
diff --git a/bin/prompts/instr_usync.md b/bin/prompts/instr_usync.md
@@ -10,3 +10,3 @@
-- Source changes are provided in `@artdef_usync_diff`.
+- Source changes are provided in `@artifact_usync_diff`.
</artifact>
<artifact id="usync_file_list" descr="Changed files since baseline">
bin/softeng.sh
bin/_lib/utils.sh
tests/unit/utils-emit-prompt.bats
</artifact>
<instruction id="instr_usync" descr="Align Working Change Folder specs with source changes">
Update the implementation plan (to-do items) in the following files to reflect source changes:

- `uspecs/changes/2604281519-add-artifact-emission-type/change.md`
- `uspecs/changes/2604281519-add-artifact-emission-type/impl.md`

...

### Source changes

- Source changes are provided in `@artifact_usync_diff`.
</instruction>
```

If the diff payload itself contained `<` or `>` (e.g. a touched HTML/XML file), those bytes would be rendered as `&lt;`/`&gt;` inside the `<artifact>` block. The agent decodes the entities transparently while the artifact's own closing `</artifact>` tag remains the only `<`/`>` sequence the parser needs to find.

References:

- [bin/_lib/utils.sh](../../../../../bin/_lib/utils.sh)
- [bin/softeng.sh](../../../../../bin/softeng.sh)
- [bin/prompts/instr_usync.md](../../../../../bin/prompts/instr_usync.md)
- [bin/prompts/artdef_usync_diff.md](../../../../../bin/prompts/artdef_usync_diff.md)
- [bin/prompts/artdef_usync_file_list.md](../../../../../bin/prompts/artdef_usync_file_list.md)
- [tests/sys/softeng.sh-action-usync.bats](../../../../../tests/sys/softeng.sh-action-usync.bats)
- [tests/unit/utils-emit-prompt.bats](../../../../../tests/unit/utils-emit-prompt.bats)

## Construction

### Tests

- [x] update: [tests/unit/utils-emit-prompt.bats](../../../../../tests/unit/utils-emit-prompt.bats)
  - add: scenario "emit_artifact round-trip with descr" -- queue a plain ASCII payload via `emit_artifact "id" "payload" "some descr"`, run `emit_prompt` against a minimal instruction, assert the payload appears byte-for-byte between literal `<artifact id="id" descr="some descr">` and `</artifact>` tags (no filtering, no `${VAR}` substitution applied to the payload)
  - add: scenario "emit_artifact entity escape" -- queue a payload `a & b <c> d </artifact> e`; assert the rendered output between the artifact tags is exactly `a &amp; b &lt;c&gt; d &lt;/artifact&gt; e`. This single assertion verifies the substitution order (no `&amp;lt;` double-escape), the `<`/`>` mappings, and that the only literal `</artifact>` in the output is the wrapper's own close
  - add: scenario "artifact + emit_prompt queue lifecycle" -- queue one artifact, run `emit_prompt` for an instruction that depends on one `@artdef_*`, assert the output contains the artifact tag, the artdef tag, and the instruction tag in order; then immediately run a second `emit_prompt` with no new artifacts queued and assert the first artifact is not re-emitted (covers both the entry-time `_EMIT_SEEN`-only reset and the post-flush `_EMIT_QUEUE` clear)
  - keep: existing two regression tests covering templated artdef behaviour

- [x] update: [tests/sys/softeng.sh-action-usync.bats](../../../../../tests/sys/softeng.sh-action-usync.bats)
  - update: "Core output" tag-shape assertions -- replace literal `<artdef id="artdef_usync_diff">` and `<artdef id="artdef_usync_file_list">` matchers with literal-string matchers `<artifact id="usync_diff"` and `<artifact id="usync_file_list"`; mirror the closing-tag assertions to literal `</artifact>`
  - add: scenario "Core output: diff payload entity-escaped" -- commit a source file containing `<`, `>`, `&` (e.g. `<div class="x">a & b</div>`), run `uspecs action usync`, assert the rendered `<artifact id="usync_diff">` body contains `&lt;div`, `a &amp; b`, `&lt;/div&gt;` and does NOT contain the raw `+<div class` diff line; verifies escaping is applied end-to-end by `cmd_action_usync`'s `emit_artifact` path
  - keep: `descr` assertions and the `is_large_diff` gating scenarios; only the tag name and id-attribute value change

### Library

- [x] update: [bin/_lib/utils.sh](../../../../../bin/_lib/utils.sh)
  - add: `_emit_xml_escape <string>` -- helper that prints the input with XML entity substitutions applied in fixed order: first `&` -> `&amp;`, then `<` -> `&lt;`, then `>` -> `&gt;`. The `&`-first ordering is essential to avoid double-escaping the entities introduced by the later substitutions. Implemented as a single `sed` pipeline (`s/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g`); `\&` is the portable literal-ampersand escape in sed replacements, sidestepping bash 5.2's `patsub_replacement` quirk in `${var//pat/repl}`
  - add: `emit_artifact <id> <payload> [descr]` -- pushes `${tag}${sep}${id}${sep}${descr}${sep}${payload}` onto `_EMIT_QUEUE` with `tag=artifact` and the existing `\x1f` separator (matching `_emit_collect`'s queue format). Performs no filtering, no `${VAR}` substitution, no `@artdef_*` dep scan, and no escaping at queue time -- the escape is applied at flush time
  - update: `emit_prompt` -- remove the `emit_prompt_reset` call at the top; replace with `_EMIT_SEEN=()` only (dedup is per-walk; `_EMIT_QUEUE` must survive so artifacts queued by the caller before this call reach the flush loop). After the flush loop completes, clear `_EMIT_QUEUE=()` so the next emission cycle starts empty
  - update: flush-loop body -- branch on `tag`. For `artdef` and `instruction`, keep the existing `<${tag} id="${id}" descr="${descr}">` / `</${tag}>` rendering. For `artifact`, call `_emit_xml_escape` on the body and print `<artifact id="${id}" descr="${descr}">`, the escaped body, then `</artifact>`
  - update: `emit_prompt_reset` doc comment -- note that it is no longer called from `emit_prompt`'s entry; it remains exported for callers that want to defensively clear state (and is still called by tests)

### Caller migration

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: `cmd_action_usync` -- drop the `[diff]` and `[file_list]` keys from the `usync_vars` associative array; immediately before the `emit_prompt` call, invoke `emit_artifact "usync_diff" "$diff_content" "Diff since baseline"` and `emit_artifact "usync_file_list" "$file_list_content" "Changed files since baseline"`. Keep `[is_large_diff]` and all other context keys in `usync_vars` as-is

- [x] update: [bin/prompts/instr_usync.md](../../../../../bin/prompts/instr_usync.md)
  - update: line ending with `(?!is_large_diff)` -- replace `` `@artdef_usync_diff` `` with `` `@artifact_usync_diff` ``
  - update: line ending with `(?is_large_diff)` (the file-list line) -- replace `` `@artdef_usync_file_list` `` with `` `@artifact_usync_file_list` ``
  - keep: gates, surrounding prose, and the `${softeng_sh}` substitution line unchanged

- [x] delete: [bin/prompts/artdef_usync_diff.md](../../../../../bin/prompts/artdef_usync_diff.md)
  - obsolete -- the `usync_diff` payload is now caller-emitted via `emit_artifact`; no `.md` template required

- [x] delete: [bin/prompts/artdef_usync_file_list.md](../../../../../bin/prompts/artdef_usync_file_list.md)
  - obsolete -- the `usync_file_list` payload is now caller-emitted via `emit_artifact`; no `.md` template required

### Out-of-scope changes carried in this branch

- [x] add: [.claude/skills/bash/SKILL.md](../../../../../.claude/skills/bash/SKILL.md)
  - unrelated to artifact emission -- a 5-line Claude skill manifest declaring a non-user-invocable `bash` skill for `*.sh` files; bundled into the same commit but not part of the change topic. Flagged for review: candidate for split into a separate change folder if a clean per-topic history is desired
