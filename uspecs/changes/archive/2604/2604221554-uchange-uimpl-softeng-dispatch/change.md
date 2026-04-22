---
registered_at: 2026-03-28T13:54:34Z
change_id: 2603281354-uchange-uimpl-softeng-dispatch
baseline: a32ee1834a2182d0c5cf2a06760f9fb8d4ddcd04
pre_pr_head: 012e31df4ea63abfb38c484812d90e3a57afa22e
archived_at: 2026-04-22T15:54:06Z
---

# Change request: uchange and uimpl softeng.sh dispatch

## Why

The `upr` and `umergepr` actions use a reliable pattern where the agent runs `softeng.sh action {keyword}` and follows structured `<AGENT_INSTRUCTIONS>` output. The `uchange`, `uimpl`, `uarchive`, and `usync` actions previously relied on the agent reading and interpreting `actn-*.md` files directly. Unifying dispatch through softeng.sh across all actions:

- removes an indirection layer and an inconsistent authoring mechanism
- enables deterministic prompt emission with variable substitution, conditional lines, and reusable artifact definitions
- lets section-authoring rules live in Claude Code skills (auto-activated by file type) instead of template files

## What

Dispatch:

- Add softeng.sh action dispatch for `uchange`, `uimpl`, `uarchive`, `usync` (aligns with existing `upr`, `umergepr`)
- Retire `uhow` and `udecs` commands entirely
- Delete `actn-uchange.md`, `actn-uimpl.md`, `actn-uarchive.md`, `actn-usync.md`, `actn-uhow.md`, `actn-udecs.md`, `conf.md`

Prompt machinery:

- Add `emit_prompt`, `_emit_collect`, `_emit_process_body`, `emit_prompt_reset` in `_lib/utils.sh`
- Split former `artdefs.md` + `prompts.md` into per-file prompts under `uspecs/u/prompts/{artdef_*,instr_*}.md` with first-line description, `${vars}`, `(?cond)`/`(?!cond)` gates, `## data` marker, and `@artdef_*` dependency refs
- Delete legacy `section_templ` helper
- Add `tests/unit/check_prompt_refs.py` + wrapper test: validates `emit_prompt` ids resolve to files, `@artdef_*` refs resolve transitively, no orphan prompt files

Skills (authoring rules moved out of artdefs, templates, and `uspecs/u/`):

- `uspecs-fd` (Functional design specifications: `.feature` + `*--reqs.md`) with `echo.feature` + `echo--reqs.md` examples
- `uspecs-domains` (domain.md) with `example-prod.md`, `example-devops.md`
- `uspecs-td` (arch.md, `*--td.md`, tech.md) with `struct-arch.md`, `struct-td.md`, `struct-tech.md`
- `uspecs-sec-domains`, `uspecs-sec-fd`, `uspecs-sec-td`, `uspecs-sec-prov`, `uspecs-sec-constr` (impl.md section authoring)
- `uspecs-concepts` (Change Folder artifacts + command list), `bats`, `python`
- `conf.sh` copies `.claude/skills/` into target repos on install/update/upgrade
- Delete templates: `tmpl-fd.md`, `tmpl-impl.md`, `tmpl-how.md`, `tmpl-decs.md`, `tmpl-change.md`, `tmpl-pr.md`
- Delete legacy sources absorbed into skills: `uspecs/u/concepts.md`, `uspecs/u/ex-domain-devops.md`

Script refactors (softeng.sh):

- New commands: `cmd_action_uchange`, `cmd_action_uimpl`, `cmd_action_uarchive`, `cmd_action_usync`
- Add `wcf_list` and `wcf_resolve_active` helpers for Working Change Folder detection
- Add `change list-wcf` subcommand; add `diff file <path>` subcommand
- Context caching: `context_project_dir`, `context_changes_folder`, `context_specs_folder`, `context_prompts_dir`, `context_is_git_repo` (hardcoded repo-root paths remove per-call conf.md reads)
- Single-pass parser in `cmd_action_uimpl` captures section flags, unchecked to-do items (incl. multi-line with sub-bullets), and review item in one file scan; `unchecked_items` var is emitted verbatim in `instr_uimpl_todos`
- `git_default_branch_name` checks local `main`/`master` before `git ls-remote` (removes network cost in hot path)
- Remove dead code: `cmd_pr_preflight`, `cmd_change_archive`, `cmd_change_archiveall`, `cmd_status_ispr`, `git_changepr`, `git_mergedef`; remove `pr preflight`, `pr create`, `change new`, `change archive`, `change archiveall`, `status` from public CLI

Action options:

- `uchange`: `--kebab-name` (required), `--no-impl`, `--branch`/`--no-branch`, `--issue-url`, `--specs` (replaces `--derive`); `--no-impl` path now emits a `## How` section into change.md (replacing the retired `uhow` command)
- `uimpl`: `--change-folder`
- `uarchive`: `--change-folder`, `--all` (per-folder ok/failed reporting, non-zero exit on failure)
- `usync`: `-y` (large-diff gate); baseline is `git merge-base ${pr_remote}/${default_branch} HEAD`; diff scope is everything outside `uspecs/specs/` and `uspecs/changes/`

Feature spec updates (non-dispatch):

- `upr.feature`: PR is created via `gh` CLI (not browser-only); `pr_body` truncated to 40 lines or 4000 chars (whichever hits first)
- `umergepr.feature`: `pr_url` displayed in success message
- `uchange.feature`, `uimpl.feature`, `uarchive.feature`, `usync.feature`: rewritten to match new dispatch and scenarios

Tests:

- New sys tests: `softeng.sh-action-uchange.bats`, `softeng.sh-action-uimpl.bats`, `softeng.sh-action-uarchive.bats`, `softeng.sh-action-usync.bats`, `softeng.sh-wcf-list.bats`
- Rename: `softeng.sh-prompt-upr.bats` -> `softeng.sh-action-upr.bats`, `softeng.sh-prompt-umergepr.bats` -> `softeng.sh-action-umergepr.bats`
- New unit tests: `git-default-branch.bats`, `utils-emit-prompt.bats` (with `check_prompt_refs.py` + `test_check_prompt_refs.py`)
- Remove obsolete tests: `softeng.sh-change-new.bats`, `softeng.sh-change-archive.bats`, `softeng.sh-change-archiveall.bats`, `softeng.sh-pr-preflight.bats`, `softeng.sh-pr-create.bats`, `utils-section-templ.bats`
- Extend: `tests/sys/softeng.sh-diff.bats` covers `diff file <path>`; `tests/e2e/conf-install.bats` covers skills installation
- `tests/run-tests.py`: add `--per-file` flag with TAP parsing for per-test reporting

Docs:

- `AGENTS.md`, `CLAUDE.md`: move `uchange`, `uimpl`, `uarchive`, `usync` from `actn-{keyword}.md` trigger list to softeng.sh dispatch list; drop `uhow`, `udecs`
- `specs/prod/softeng/arch.md` and affected `*.feature` files updated to match new dispatch
- `.claude/skills/uspecs-concepts/SKILL.md` refreshed (commands list, Change Folder artifacts)
