# Implementation plan: Rename uspecs.sh and move prompts.md

## Construction

### File renames

- [x] rename: `uspecs/u/scripts/uspecs.sh` -> [u/scripts/softeng.sh](../../u/scripts/softeng.sh)
  - update: self-reference in `script_path` variable from `uspecs.sh` to `softeng.sh`
  - update: usage comment block at top to reflect new name
  - update: usage error messages in `main()` from `uspecs` to `softeng`
- [x] move: `uspecs/u/scripts/prompts.md` -> [u/prompts.md](../../u/prompts.md)

### References in uspecs.sh (now softeng.sh)

- [x] update: [u/scripts/softeng.sh](../../u/scripts/softeng.sh)
  - update: `prompts_file` assignments (lines 836, 995) from `get_script_dir` to point to `../../u/prompts.md` relative path

### Agent configuration

- [x] update: [AGENTS.md](../../../AGENTS.md)
  - update: `uspecs/u/scripts/uspecs.sh` -> `uspecs/u/scripts/softeng.sh` in execution instructions
- [x] update: [CLAUDE.md](../../../CLAUDE.md)
  - update: `uspecs/u/scripts/uspecs.sh` -> `uspecs/u/scripts/softeng.sh` in execution instructions

### Action files

- [x] update: [u/actn-uchange.md](../../u/actn-uchange.md)
  - update: `uspecs/u/scripts/uspecs.sh` -> `uspecs/u/scripts/softeng.sh` in base command
- [x] update: [u/actn-uarchive.md](../../u/actn-uarchive.md)
  - update: all `uspecs/u/scripts/uspecs.sh` -> `uspecs/u/scripts/softeng.sh` references
- [x] update: [u/actn-upr_deprecated.md](../../u/actn-upr_deprecated.md)
  - update: all references from `uspecs.sh` to `softeng.sh`

### Specs

- [x] update: [specs/prod/softeng/arch.md](../../specs/prod/softeng/arch.md)
  - update: `uspecs.sh` -> `softeng.sh` references
  - update: `prompts.md` path reference

### CI/scripts

- [x] update: [scripts/pr-uaccept.sh](../../../scripts/pr-uaccept.sh)
  - update: `uspecs/u/scripts/uspecs.sh` -> `uspecs/u/scripts/softeng.sh`

### Tests

- [x] update: [tests/sys/helpers.bash](../../../tests/sys/helpers.bash)
  - update: `uspecs/u/scripts/uspecs.sh` -> `uspecs/u/scripts/softeng.sh` in `uspecs()` helper and comments
