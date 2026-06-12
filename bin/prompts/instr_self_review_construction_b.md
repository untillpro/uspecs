# Self-review: construction (Stage B)

## data

Review the construction artifacts that were just changed (or added) by `uimpl` for:

- DRY (no duplicated logic or constants)
- SOLID principles (single responsibility, open/closed, etc.)

DRY example:

- If two call sites use near-identical regex predicates, extract one helper and call it from both places. For example, replace duplicated `review` item checks such as:

```bash
if [[ "$_lower" =~ ^-[[:space:]]+\[[[:space:]]+\][[:space:]]+review($|[[:space:]]) ]]; then

...

if [[ "$_lower" =~ ^-[[:space:]]+(\[[[:space:]]+\][[:space:]]+)?review($|[[:space:]]) ]]; then
```

with a single predicate:

```bash
_uimpl_is_review_item() {
	local _lower_item="$1"
	[[ "$_lower_item" =~ ^-[[:space:]]+(\[[[:space:]]+\][[:space:]]+)?review($|[[:space:]]) ]]
}
```

Rules:

- For each issue found, fix it inline; do not stop to ask the user
- Do not re-run this stage

After fixing all issues:

- Report results to the user: files reviewed, issues found, fixes applied, and any outstanding issues
