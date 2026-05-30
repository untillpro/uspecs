# Decisions: Frontmatter domain field

## Ambiguity: no-domain behavior for frontmatter domain metadata

Decision: Omit the `domains` frontmatter field when no specification domain folder exists.

- Pros: Matches the requested condition that domain metadata is emitted only if a specification folder exists; keeps frontmatter minimal and avoids empty metadata.
- Cons: Consumers must handle the field being absent.
- Confidence: high

Alternatives:

1. Emit `domains: []` when no specification domain folder exists.
   - Pros: Gives consumers a stable frontmatter key.
   - Cons: Conflicts with the "only if spec folder exists" wording and may imply domain detection ran successfully.
   - Confidence: medium
2. Emit no `domains` field and add a non-frontmatter note in `## What`.
   - Pros: Makes behavior visible to readers without changing metadata shape.
   - Cons: Provides a weaker machine-readable contract.
   - Confidence: low

## Ambiguity: frontmatter field name for affected domains

Decision: Use `domains` as the frontmatter field name with a list value.

- Pros: Matches the list shape and makes multi-domain changes explicit.
- Cons: Differs from earlier singular "domain field" wording.
- Confidence: high

Alternatives:

1. Use `domain` as the frontmatter field name with a list value.
   - Pros: Preserves the earlier singular field wording while still supporting multiple affected domains.
   - Cons: A singular key with a list value is mildly misleading.
   - Confidence: medium
2. Allow either `domain` or `domains`.
   - Pros: Flexible for callers and existing artifacts.
   - Cons: Creates avoidable ambiguity for downstream consumers.
   - Confidence: low

## Inconsistency: frontmatter field name differs between `change.md` and recorded decisions

Decision: Standardize on `domains` as the frontmatter field name.

- Pros: Matches the current `change.md`, matches the list value shape, and makes multi-domain intent clear.
- Cons: Requires updating earlier decision text that used `domain`.
- Confidence: high

Alternatives:

1. Standardize on `domain` as the frontmatter field name with a list value.
   - Pros: Preserves the earlier recorded decision.
   - Cons: Conflicts with the current `change.md` text and is less clear for a list-valued field.
   - Confidence: medium
2. Allow both `domain` and `domains`.
   - Pros: Gives compatibility flexibility.
   - Cons: Creates avoidable ambiguity for downstream prompts and reviewers.
   - Confidence: low

## Vagueness: exact value format for entries in the `domains` frontmatter list

Decision: Use domain directory names from `uspecs/specs/{domain}/domain.md` as `domains` list values.

- Pros: Produces distinct values like `prod` and `devops`; matches the existing discovery pattern; keeps values compact.
- Cons: Requires consumers to know that values map back to domain specs through the standard `uspecs/specs/{domain}/domain.md` location.
- Confidence: high

Alternatives:

1. Use domain file names without extension.
   - Pros: Matches the earlier free-form wording.
   - Cons: Conflicts with the existing `uspecs/specs/{domain}/domain.md` layout because every domain spec file is named `domain.md`.
   - Confidence: low
2. Use relative paths to each domain spec, such as `uspecs/specs/prod/domain.md`.
   - Pros: Fully explicit and easy to navigate.
   - Cons: Noisy for frontmatter; duplicates the known domain-spec layout; less suitable as compact metadata.
   - Confidence: medium
3. Use display names or headings from each domain spec file.
   - Pros: More readable for humans.
   - Cons: Less stable for automation; requires parsing file contents beyond discovering the domain specs.
   - Confidence: low

## Inconsistency: `domain file names without extension` conflicts with current domain spec layout

Decision: Use domain directory names from `uspecs/specs/{domain}/domain.md`.

- Pros: Produces distinct values like `prod` and `devops`; matches the existing discovery pattern; keeps values compact.
- Cons: Revises the previous wording from file names to directory names.
- Confidence: high

Alternatives:

1. Keep domain file names without extension and require a different domain spec layout.
   - Pros: Preserves the previous wording.
   - Cons: Conflicts with the existing documented path `uspecs/specs/{domain}/domain.md`; would imply broader spec layout changes.
   - Confidence: low
2. Use relative paths to domain specs.
   - Pros: Avoids ambiguity and works with the current layout.
   - Cons: More verbose frontmatter than compact domain IDs.
   - Confidence: medium

## Ambiguity: when `domains` should be emitted during `uchange`

Decision: Emit `domains` for every generated `change.md` when domain specs exist.

- Pros: Matches the goal that metadata is available before the default behavior summary; makes blast-radius metadata consistent regardless of planning options.
- Cons: Requires domain-identification instructions even for minimal change creation flows.
- Confidence: high

Alternatives:

1. Emit `domains` only when specification or planning sections are requested.
   - Pros: Aligns with the current planning-context gating.
   - Cons: Weakens the metadata contract; reviewers may not get domain frontmatter on ordinary generated changes.
   - Confidence: medium
2. Emit `domains` only when the change authoring prompt can confidently infer affected domains.
   - Pros: Avoids low-confidence metadata.
   - Cons: Leaves unclear whether omission means no domain specs exist or domain inference was uncertain.
   - Confidence: low

## Uncertainty: what to do when affected domains cannot be inferred confidently from the change request input

Decision: Always emit a best-effort guessed `domains` list.

- Pros: Preserves the contract that `domains` is present whenever domain specs exist; keeps change creation non-interactive; gives reviewers an early blast-radius hint even when input is sparse.
- Cons: Guessed metadata can be wrong or incomplete and may need reviewer correction.
- Confidence: user-provided

Alternatives:

1. Ask the Engineer to choose affected domains before writing `change.md`.
   - Pros: Avoids misleading metadata.
   - Cons: Adds an interactive step for ambiguous `uchange` requests.
   - Confidence: high
2. Emit all existing domain directory names.
   - Pros: Keeps `uchange` non-interactive and guarantees the field is present.
   - Cons: Overstates blast radius and makes the metadata less useful.
   - Confidence: medium
3. Omit `domains` when inference is uncertain.
   - Pros: Avoids false metadata.
   - Cons: Conflicts with the decision to emit `domains` for every generated `change.md` when domain specs exist.
   - Confidence: low

## Ambiguity: which component is responsible for choosing affected `domains`

Decision: AI Agent discovers valid domains by scanning `uspecs/specs/*/domain.md`, then guesses affected `domains` from that set.

- Pros: No bash semantic inference; no need for bash to pass a domain list; matches the existing domain-file pattern directly.
- Cons: Duplicates discovery logic that `softeng.sh` already partially has for `domains_defined`; prompt must constrain values to directory names from matched paths.
- Confidence: high

Alternatives:

1. Bash provides the list of domain directory names, Agent chooses affected ones.
   - Pros: Keeps filesystem discovery centralized and avoids prompt-side path scanning.
   - Cons: Requires adding a new prompt variable or artifact before `change_frontmatter`.
   - Confidence: high
2. Agent guesses without scanning domain files.
   - Pros: Lowest implementation effort.
   - Cons: Can emit invalid domain IDs or miss available domain names.
   - Confidence: low
