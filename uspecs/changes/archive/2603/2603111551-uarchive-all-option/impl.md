# Implementation plan: uarchive --all option

## Functional design

- [x] update: [specs/prod/softeng/uarchive.feature](../../../../specs/prod/softeng/uarchive.feature)
  - add: scenario for `--all` option: no Active Change Folder argument needed; all change folders modified vs `pr_remote/default_branch` are archived

## Construction

- [x] update: [u/actn-uarchive.md](../../../../u/actn-uarchive.md)
  - add: `--all` to Parameters/Input with note that no Active Change Folder path is needed
  - add: flow branch for `--all` option (fetch remote, enumerate change folders, check diff vs pr_remote/default_branch, archive each modified folder, report counts)

- [x] update: [tests/sys/uspecs.sh-change-archive.bats](../../../../../tests/sys/uspecs.sh-change-archive.bats)
  - test: `change archive --all` archives multiple modified change folders (two folders) and reports counts
  - test: `change archive --all` skips folders unchanged vs origin/main: four folders covering same-as-main (unchanged), deleted-from-main, modified-in-branch, new-in-branch; asserts 3 archived 1 unchanged
  - test: `change archive --all` reports failed count when folder has uncompleted items
  - test: `change archive --all` with folder name argument fails
  - test: `change archive --all` combined with `-d` fails

- [x] update: [u/scripts/uspecs.sh](../../../../u/scripts/uspecs.sh)
  - add: `--all` flag parsing in `cmd_change_archive`
  - add: mutual-exclusivity checks: `--all` vs folder name, `--all` vs `-d`
  - add: `--all` mode implementation: require git, get pr_remote/default_branch via `get_pr_info`, fetch remote, iterate change folders (skip `archive/`), check `git diff --name-only pr_remote/default_branch HEAD -- rel_folder`, archive each modified folder via subprocess call to the script itself, report archived/unchanged/failed counts
  - update: usage comment block at top of file to document `--all`

## Quick start

Archive all change folders modified relative to remote default branch:

```bash
bash uspecs/u/scripts/uspecs.sh change archive --all
```
