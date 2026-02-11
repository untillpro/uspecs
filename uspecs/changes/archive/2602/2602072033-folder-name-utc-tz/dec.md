# Decisions: Change Folder name must use UTC time zone

## Scope of the change

Update only the `conf.md` specification text (confidence: high).

Rationale: The `uspecs.sh` script already uses `date -u` (UTC) for both `get_timestamp()` and the archive `date_prefix`. The script is already compliant. Only the human-facing specification text in `conf.md` says "Must use current local date", which is what AI Agents and engineers read when creating Change Folders manually or via the `uchange` flow.

Alternatives:

- Update both `conf.md` and `uspecs.sh` (confidence: low)
  - The script already uses `-u` flag, so no script change is needed
- Update `conf.md`, `uspecs.sh`, and `actn-uchange.md` (confidence: low)
  - `actn-uchange.md` does not mention time zones at all; it delegates naming to `conf.md`

## Terminology: UTC

Use "UTC" in the specification text (confidence: high).

Rationale: UTC is the actual time standard. The `date -u` command outputs UTC, and the `Z` suffix in frontmatter timestamps (e.g., `2026-02-07T20:24:18Z`) stands for "Zulu time", which is UTC. Using UTC aligns the specification with the existing script behavior.

## Wording of the replacement text

Replace "Must use current local date" with "Must use current date and time in UTC" (confidence: high).

Rationale: Keeps the sentence structure similar to the original while clearly specifying the time zone. The word "date" alone is ambiguous since the format includes both date and time components (ymdHM), so adding "and time" improves clarity.

Alternatives:

- "Must use current UTC date and time" (confidence: medium)
  - Puts "UTC" before "date and time" which reads slightly less naturally
- "Must use current date in UTC" (confidence: medium)
  - Omits "and time", which is less precise given the format includes hours and minutes

## Example line update

Update the example to clarify UTC context (confidence: medium).

Rationale: The current example "For 2006-01-02 15:04, use prefix 2601021504" does not mention time zone. Adding "(UTC)" to the example reinforces the UTC requirement.

Alternatives:

- Leave the example unchanged (confidence: medium)
  - The example is illustrative and the UTC rule is stated in the line above; adding UTC to the example may be redundant
- Replace the example with a more realistic one (confidence: low)
  - Unnecessary churn for a minor clarification

## Impact on existing Change Folders

No retroactive renaming of existing folders (confidence: high).

Rationale: Existing Active and Archived Change Folders were created under the old "local date" rule. Renaming them would break git history, relative links in `impl.md` files, and `change_id` values in frontmatter. The new rule applies only to newly created Change Folders going forward.

Alternatives:

- Rename all existing folders to UTC-based timestamps (confidence: low)
  - High risk, breaks references, no practical benefit
