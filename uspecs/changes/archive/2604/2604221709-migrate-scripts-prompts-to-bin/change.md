---
registered_at: 2026-04-22T16:06:08Z
change_id: 2604221606-migrate-scripts-prompts-to-bin
baseline: 7197f00d538d722d1c053b59a002ce62595f9caf
archived_at: 2026-04-22T17:09:52Z
---

# Change request: Migrate u/scripts and u/prompts to bin and bin/prompts

## Why

The `uspecs/u/` directory is an installation-internal folder whose sub-structure (`scripts/`, `prompts/`, `templates/`) adds unnecessary nesting. Flattening it to `bin/` and `bin/prompts/` makes the layout simpler and more conventional, removing a layer of indirection from every path reference in scripts and specs.

## What

Move script and prompt files out of `uspecs/u/` into a flat `bin/` structure and eliminate the now-empty `uspecs/u/` directory:

- `uspecs/u/scripts/` → `bin/`
- `uspecs/u/prompts/` → `bin/prompts/`
- Remove `uspecs/u/templates/tmpl-td.md` (unused — `templates_folder` context variable is set but never consumed by any prompt)
- Delete `uspecs/u/` entirely
- Update `AGENTS.md` source template: `bash uspecs/u/scripts/softeng.sh` → `bash bin/softeng.sh` (conf.sh injects from this file, so stale path would be re-injected on every install/update)

## Technical design

- [x] update: [conf/arch.md](../../../../specs/prod/conf/arch.md)
  - update: component links from `u/scripts/conf.sh`, `u/scripts/_lib/git.sh`, `u/scripts/_lib/utils.sh` to `bin/conf.sh`, `bin/_lib/git.sh`, `bin/_lib/utils.sh`
  - update: curl-pipe install flow path `uspecs/u/scripts/conf.sh` → `bin/conf.sh`
  - update: apply flow path `uspecs/u` → `bin` in copy-files step
  - update: `uspecs.yml` path `uspecs/u/uspecs.yml` → `bin/uspecs.yml`

- [x] update: [softeng/arch.md](../../../../specs/prod/softeng/arch.md)
  - remove: `templates/` participant from generic flow diagram (templates_folder is being eliminated)
  - remove: template-related references in action examples
  - fix: stale `u/prompts.md` reference in umergepr example (line 64)

- [x] update: [devops/arch.md](../../../../specs/devops/arch.md)
  - update: `uspecs/u/` → `bin/` in line endings convention section

## Construction

### File layout

- [x] move: `uspecs/u/scripts/` → `bin/` (`softeng.sh`, `conf.sh`, `_lib/git.sh`, `_lib/utils.sh`)
- [x] move: `uspecs/u/prompts/` → `bin/prompts/`
- [x] delete: `uspecs/u/templates/tmpl-td.md`
- [x] delete: `uspecs/u/` directory

### Script path updates

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: `context_prompts_dir` — `$_CTX_SCRIPT_DIR/../prompts` → `$_CTX_SCRIPT_DIR/prompts`
  - remove: `[templates_folder]="uspecs/u/templates"` from both context_vars blocks
  - update: `next_command` values — `bash uspecs/u/scripts/softeng.sh` → `bash bin/softeng.sh`

- [x] update: [bin/conf.sh](../../../../../bin/conf.sh)
  - update: `get_project_dir` — depth `../../..` → `..` (script moved from 3 levels deep to 1)
  - update: `get_local_version` — `$script_dir/../../../version.txt` → `$script_dir/../version.txt`
  - update: `get_local_commit_info` — `$script_dir/../../..` → `$script_dir/..`
  - update: `source_dir` in `apply` — `$script_dir/../../..` → `$script_dir/..`
  - update: all `uspecs/u/uspecs.yml` → `bin/uspecs.yml`
  - update: `bash "$temp_dir/uspecs/u/scripts/conf.sh"` → `bash "$temp_dir/bin/conf.sh"`
  - update: `replace_uspecs_u` — `find/cp` paths `uspecs/u` → `bin`, copy destination `$project_dir/uspecs/` → `$project_dir/`
  - update: `mkdir -p "$project_dir/uspecs/u"` → `mkdir -p "$project_dir/bin"`

### Config and invocation

- [x] update: [AGENTS.md](../../../../../AGENTS.md)
  - update: `bash uspecs/u/scripts/softeng.sh` → `bash bin/softeng.sh` in the `<!-- uspecs:begin -->` block

- [x] update: [CLAUDE.md](../../../../../CLAUDE.md)
  - update: `bash uspecs/u/scripts/softeng.sh` → `bash bin/softeng.sh` in the `<!-- uspecs:begin -->` block

### Tests

- [x] update: [tests/e2e/conf-install.bats](../../../../../tests/e2e/conf-install.bats)
  - update: `CONF_SH` path `uspecs/u/scripts/conf.sh` → `bin/conf.sh`
  - update: all `uspecs/u/uspecs.yml` → `bin/uspecs.yml`
  - update: `uspecs/u/stale-file.txt` → `bin/stale-file.txt`
  - update: `mkdir -p "$tmpdir/uspecs/u"` → `mkdir -p "$tmpdir/bin"`

- [x] update: [tests/sys/conf.sh-apply.bats](../../../../../tests/sys/conf.sh-apply.bats)
  - update: `uspecs/u/uspecs.yml` → `bin/uspecs.yml`
  - update: `uspecs/u/scripts/conf.sh` → `bin/conf.sh`

- [x] update: [tests/sys/helpers.bash](../../../../../tests/sys/helpers.bash)
  - update: `cp -r "$REPO_ROOT/bin" "$PROJECT_ROOT/uspecs/"` → `cp -r "$REPO_ROOT/bin" "$PROJECT_ROOT/"` (copy destination matches new layout)
  - update: `uspecs/u/scripts/softeng.sh` → `bin/softeng.sh`

- [x] update: all unit test files sourcing `uspecs/u/scripts/_lib/`
  - update: `$REPO_ROOT/uspecs/u/scripts/_lib/utils.sh` → `$REPO_ROOT/bin/_lib/utils.sh` in utils-atexit.bats, utils-emit-prompt.bats, utils-md.bats, utils-prompt.bats, utils-quiet.bats
  - update: `$REPO_ROOT/uspecs/u/scripts/_lib/git.sh` → `$REPO_ROOT/bin/_lib/git.sh` in git-default-branch.bats

- [x] update: [tests/unit/check_prompt_refs.py](../../../../../tests/unit/check_prompt_refs.py)
  - update: `uspecs/u/scripts/softeng.sh` → `bin/softeng.sh`
  - update: `uspecs/u/prompts` → `bin/prompts`

- [x] run tests and fix problems
  - 54/54 unit tests pass
  - 82/82 sys tests pass
  - 9/11 e2e tests pass; 2 remote-download tests (`alpha nlia`, `curl pipe`) remain failing until a new release is published with the `bin/` layout
