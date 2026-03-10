# Implementation plan: Use Python instead of Bash

## Provisioning and configuration

- [ ] verify: Python 3.8+ is available on the system
  - `python --version` or `python3 --version`

## Technical design

- [ ] update: [devops/devops--arch.md](../../specs/devops/devops--arch.md)
  - update: Document Python as the scripting language for uspecs tooling (replacing Bash)

## Construction

### Script rewrite

- [ ] create: [u/scripts/uspecs.py](../../u/scripts/uspecs.py)
  - Port all commands from `uspecs.sh`: `change new`, `change prompt`, and any other subcommands
  - Maintain identical CLI interface (same arguments, options, output format)
  - Port helper logic from `u/scripts/_lib/utils.sh` and `u/scripts/_lib/pr.sh`

- [ ] create: [u/scripts/sp/](../../u/scripts/sp/)
  - Keep existing `sp/` markdown files (sp-actn-uchange.md, sp-actn-uimpl.md, etc.) as-is; no changes needed

### Reference updates

- [ ] update: [CLAUDE.md](../../../CLAUDE.md)
  - update: `bash uspecs/u/scripts/uspecs.sh` references to use `python uspecs/u/scripts/uspecs.py`

- [ ] update: [u/scripts/conf.sh](../../u/scripts/conf.sh)
  - evaluate: Remove or convert if it only exists to support the Bash script

### Cleanup

- [ ] delete: [u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)
  - Remove old Bash entry point after Python replacement is verified
- [ ] delete: [u/scripts/_lib/utils.sh](../../u/scripts/_lib/utils.sh)
  - Remove if fully ported to Python
- [ ] delete: [u/scripts/_lib/pr.sh](../../u/scripts/_lib/pr.sh)
  - Remove if fully ported to Python

### Tests

- [ ] update: [devops/dev/uspecs-sh-tests.feature](../../specs/devops/dev/uspecs-sh-tests.feature)
  - update: Rename/update to reflect Python script (`uspecs.py`) instead of `uspecs.sh`

## Quick start

Run the new Python script:

```bash
python uspecs/u/scripts/uspecs.py change prompt
python uspecs/u/scripts/uspecs.py change new my-change-name
```
