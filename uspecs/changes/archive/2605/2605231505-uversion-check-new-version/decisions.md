# Decisions: uversion-check-new-version

## Vagueness: source used to determine whether a newer version is available

Decision: Check the same per-agent plugin marketplace stream that supplied the installed plugin.

- Pros: matches the existing install/update model; avoids mixing stable and development streams; keeps the result relevant to the user's current agent host
- Cons: requires the action to know or infer the matching marketplace stream; does not report cross-stream upgrades
- Confidence: high

Alternatives:

1. Check the same per-agent plugin marketplace stream that supplied the installed plugin
   - Pros: matches the existing install/update model; avoids mixing stable and development streams; keeps the result relevant to the user's current agent host
   - Cons: requires the action to know or infer the matching marketplace stream; does not report cross-stream upgrades
   - Confidence: high
2. Check the source repository tags and main branch directly
   - Pros: independent of marketplace refresh state; can see source releases quickly
   - Cons: diverges from the plugin installation path; must map source versions back to agent-specific plugin artifacts
   - Confidence: medium
3. Check every uspecs marketplace stream
   - Pros: can reveal both stable and development options
   - Cons: noisier output; may suggest a stream switch rather than an update of the installed plugin
   - Confidence: low

## Ambiguity: how to compare stable, development, and source versions

Decision: Compare stable installations by semantic version, compare development installations by their timestamped dev build version, and skip availability checks for the source sentinel version.

- Pros: respects the existing stable and development version schemes; avoids treating SemVer build metadata as ordered for stable releases; gives source checkouts a clear non-marketplace behavior
- Cons: development version ordering depends on the generated timestamp convention remaining stable
- Confidence: high

Alternatives:

1. Compare stable installations by semantic version, compare development installations by their timestamped dev build version, and skip availability checks for the source sentinel version
   - Pros: respects the existing stable and development version schemes; avoids treating SemVer build metadata as ordered for stable releases; gives source checkouts a clear non-marketplace behavior
   - Cons: development version ordering depends on the generated timestamp convention remaining stable
   - Confidence: high
2. Use raw lexicographic string comparison for every version
   - Pros: simple to implement
   - Cons: can misclassify semantic versions and treats source sentinel values as comparable published versions
   - Confidence: low
3. Always compare only semantic version core values
   - Pros: straightforward for stable releases
   - Cons: loses the timestamp and commit information needed to distinguish development builds
   - Confidence: low

## Uncertainty: behavior when the availability check cannot complete

Decision: Keep uversion best-effort: always display the installed version, and report availability as unknown with a concise reason when the check cannot complete.

- Pros: preserves the current core behavior; avoids turning an informational command into a failure-prone workflow; gives users enough context to decide whether to retry
- Cons: users may need a separate manual check when network or marketplace metadata is unavailable
- Confidence: high

Alternatives:

1. Keep uversion best-effort: always display the installed version, and report availability as unknown with a concise reason when the check cannot complete
   - Pros: preserves the current core behavior; avoids turning an informational command into a failure-prone workflow; gives users enough context to decide whether to retry
   - Cons: users may need a separate manual check when network or marketplace metadata is unavailable
   - Confidence: high
2. Fail the action when availability cannot be checked
   - Pros: makes check failures impossible to overlook
   - Cons: regresses the simple "show installed version" use case
   - Confidence: low
3. Suppress availability output when the check cannot complete
   - Pros: keeps output short
   - Cons: hides the difference between "up to date" and "unknown"
   - Confidence: low

## Vagueness: how uversion checks the latest version in the same marketplace stream

Decision: Generate `USPECS_MARKETPLACE_REPO` in `bin/softeng.sh` and fetch that repository's generated marketplace manifest directly.

- Pros: host-independent; works the same for Claude, Augment, and Codex; uses the same marketplace stream named by the generated plugin; does not require install/update commands
- Cons: requires network access and a stable raw GitHub URL convention for `uspecs/<marketplace_repo>`
- Confidence: high

Alternatives:

1. Generate `USPECS_MARKETPLACE_REPO` in `bin/softeng.sh` and fetch that repository's generated marketplace manifest directly
   - Pros: host-independent; works the same for Claude, Augment, and Codex; uses the same marketplace stream named by the generated plugin; does not require install/update commands
   - Cons: requires network access and a stable raw GitHub URL convention for `uspecs/<marketplace_repo>`
   - Confidence: high
2. Use each host CLI to refresh marketplace metadata, then inspect host-local marketplace state
   - Pros: aligns closely with how users update plugins in each host
   - Cons: host-specific paths and behavior; may mutate local marketplace state; harder to test consistently
   - Confidence: medium
3. Do not perform an automated latest-version check; only print update instructions from `AGENT_CONFIGS`
   - Pros: simple and reliable; no network or host metadata dependency
   - Cons: does not satisfy the requirement to report whether a newer version is available
   - Confidence: low

## Ambiguity: which field in the marketplace repo is the latest version source

Decision: Use `.claude-plugin/marketplace.json` `metadata.version`.

- Pros: single generated marketplace-level version; already exists in the marketplace repository; same for stable and development streams
- Cons: assumes marketplace metadata version remains the authoritative version for the plugin it lists
- Confidence: high

Alternatives:

1. Use `.claude-plugin/marketplace.json` `metadata.version`
   - Pros: single generated marketplace-level version; already exists in the marketplace repository; same for stable and development streams
   - Cons: assumes marketplace metadata version remains the authoritative version for the plugin it lists
   - Confidence: high
2. Fetch the plugin's `.claude-plugin/plugin.json` and use its `version`
   - Pros: reads the version from the actual plugin manifest
   - Cons: requires following the marketplace plugin source path; slightly more logic and more failure points
   - Confidence: medium
3. Fetch both and require them to match
   - Pros: detects generator inconsistencies
   - Cons: makes `uversion` more fragile for a health-check command; mismatch handling adds noise
   - Confidence: medium
