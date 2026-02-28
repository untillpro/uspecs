---
registered_at: 2026-02-28T18:56:08Z
change_id: 2602281856-extract-loader-sh
baseline: ef926fac77063bb965a9f3ec3c789a6963be4a79
---

# Change request: Extract loader.sh from conf.sh

## Why

The download-and-apply logic (create temp dir, download archive, invoke apply from the downloaded version) is duplicated inside `cmd_install` and `cmd_update_or_upgrade` in `conf.sh`. Extracting it into a dedicated `loader.sh` separates the concern of bootstrapping a target version from the user-facing command logic.

## What

New file `uspecs/u/scripts/loader.sh`:

- accepts `<ref> <apply-args...>`
- owns: OS-specific tmp setup, `_TEMP_DIRS` array, `create_temp_dir`, `download_archive`, cleanup trap
- downloads the archive for the given ref, then calls `bash "$temp_dir/uspecs/u/scripts/conf.sh" apply <apply-args...>`

Changes to `uspecs/u/scripts/conf.sh`:

- remove `download_archive` function (moved to loader.sh)
- remove `create_temp_dir` function (moved to loader.sh)
- remove `_TEMP_DIRS` array and the dirs-half of `cleanup_temp` (moved to loader.sh; `_TEMP_FILES` and its cleanup remain)
- `cmd_install`: replace the inline create/download/apply block with a single call to `loader.sh "$ref" "${apply_args[@]}"`
- `cmd_update_or_upgrade`: same replacement with `loader.sh "$target_ref" "${apply_args[@]}"`
