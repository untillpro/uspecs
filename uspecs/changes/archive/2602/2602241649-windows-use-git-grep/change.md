---
registered_at: 2026-02-24T14:23:03Z
change_id: 2602241423-windows-use-git-grep
baseline: c4732720f507fa263f7f9623ab52175639607a35
issue_url: https://untill.atlassian.net/browse/AIR-3062
archived_at: 2026-02-24T16:49:18Z
---

# Change request: On Windows use grep from git install

## Why

Windows may have multiple grep installations, and some do not support all options used by the uspecs scripts, causing script failures. See [issue.md](issue.md) for details.

## What

Update uspecs scripts to prefer grep from the git (MSYS2/Bash) installation on Windows:

- Detect Windows environment in uspecs scripts
- Resolve and use the grep bundled with git (e.g. from MSYS2) instead of relying on the system PATH
