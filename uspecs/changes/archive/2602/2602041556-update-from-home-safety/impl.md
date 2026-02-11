# Implementation plan: Add safety checks and version tracking to update-from-home.sh

## Construction

- [x] update: [scripts/update-from-home.sh](../../../../u/scripts/update-from-home.sh)
  - add: Check for uncommitted git changes in TARGET_ROOT before sync
  - add: Save version info to uspecs/version.txt after successful sync

## Quick start

Check for uncommitted changes and sync with version tracking:

```bash
bash uspecs/u/scripts/update-from-home.sh
```

The script will:

- Exit with error if target directory has uncommitted changes
- Create `uspecs/version.txt` with format `YYYYMMDDhhmmss-<commit12>` after sync
