# Change: Use yq for domain build with bash fallback

- archived_at: 2025-12-17T23:10:50Z
- registered_at: 2025-12-17T22:23:52Z
- change_id: 251217-use-yq-for-domain-build
- baseline: bb09922d7412b51b6643b3137e8e412b8b27fb7a

## Problem

The current domains-build.sh script uses bash-native YAML parsing with awk/sed/grep, which is fragile and difficult to maintain. Complex YAML structures require intricate parsing logic that is error-prone and hard to debug.

## Proposal

Update domains-build.sh to use yq (YAML processor) for parsing contexts.yml, with automatic fallback to the existing bash implementation when yq is not available.

Scope:

- Detect yq v4+ availability at runtime
- Use yq for YAML parsing when available (cleaner, more reliable)
- Fallback to existing bash/awk/sed parsing when yq is not installed
- Add option to explicitly specify yq usage (--use-yq flag)
- Add option to explicitly disable yq and force bash parsing (--no-yq flag)
- Add verbose flag (--verbose or -v) to show which parsing method is active

Implementation details:

- Add check_yq() function to detect yq v4+ availability and version
- Create yq-based parsing functions using yq eval syntax (get_domains_yq, get_participants_yq, etc.)
- Keep existing bash parsing functions as fallback
- Add command-line flag parsing for --use-yq, --no-yq, and --verbose options
- Default behavior: auto-detect yq and use if available, silent operation
- Strict flag enforcement:
  - --use-yq when yq not available: error with message to install yq or remove flag
  - --no-yq: force bash implementation regardless of yq availability
  - --verbose: print parsing method being used
- Treat yq v3 as "not available" and use bash fallback with version warning
