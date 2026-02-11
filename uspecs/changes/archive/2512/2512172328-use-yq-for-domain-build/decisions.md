# Decisions

## Support yq v4+ only

Decision: The script will support yq v4+ (mikefarah/yq) only, not the older v3 version.

Rationale:

- yq v4 is the current maintained version with better features and active development
- Simpler implementation - only one yq syntax to support (yq eval '.path' file.yml)
- Most users installing yq today will get v4+ from package managers
- Can detect version with `yq --version` and provide clear guidance if v3 is detected
- Reduces maintenance burden by not supporting legacy version

Alternatives considered:

- Support both yq v3 and v4+ - Rejected because it adds complexity for detecting version and using different syntax, plus maintenance burden for legacy version
- Support yq v4+ with automatic fallback to bash for v3 - Rejected in favor of treating v3 as "not available" with a warning message to upgrade

Implementation:

- Detect yq version with `yq --version`
- If v3 detected, print warning: "yq v3 detected, please upgrade to v4+. Using bash fallback."
- Treat v3 as "not available" and use bash implementation

## Strict flag enforcement with clear error messages

Decision: Explicit flags (--use-yq, --no-yq) will be strictly enforced with clear error messages when requirements cannot be met.

Rationale:

- Explicit flags should be honored or fail clearly to respect user intent
- Predictable behavior - users know exactly what will happen
- Helps catch configuration issues early (e.g., CI environment missing yq)
- Clear error messages guide users to resolution

Alternatives considered:

- Soft flag enforcement with automatic fallback - Rejected because it makes behavior less predictable and may hide configuration issues
- Add --require-yq flag for strict enforcement - Rejected because --use-yq already implies intent to use yq, adding another flag is redundant

Implementation:

- `--use-yq` when yq not available → Error: "yq not found. Install yq v4+ or remove --use-yq flag"
- `--no-yq` when yq available → Use bash implementation (no error)
- No flags → Auto-detect and use yq if available, bash otherwise

## Silent operation with optional verbose flag

Decision: The script will operate silently by default, with an optional --verbose flag to show which parsing method is being used.

Rationale:

- Clean output by default keeps script output focused on generated files
- Better for scripting and automation workflows
- Verbose mode available when debugging or troubleshooting
- Follows Unix philosophy of silent success

Alternatives considered:

- Always show parsing method in output - Rejected because it clutters output for automated workflows and adds noise
- Show parsing method only when using fallback - Rejected because it's inconsistent (sometimes shows, sometimes doesn't) and may still be noisy

Implementation:

- Default: No output about parsing method, only print generated file paths
- `--verbose` or `-v` flag: Print "Using yq v4 for YAML parsing" or "Using bash fallback for YAML parsing"
- Error messages always shown regardless of verbose flag

## References

- https://github.com/mikefarah/yq - yq v4+ official repository and documentation
- https://mikefarah.gitbook.io/yq/ - yq v4+ usage guide and examples
- https://www.baeldung.com/linux/yq-utility-processing-yaml - yq tutorial for YAML processing in bash
