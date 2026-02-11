# Questions about the Change Implementation

## 1. Output File Naming Discrepancy

The change.md says:
> build-rels.sh creates domain-{context-name}.md per domain in contexts.yml

But build-relationships.md specifies:
> One or more relationship diagram files: `uspecs/relationships-{domain}.md`

**Question**: Which naming convention should be used?

- `domain-{domain-name}.md` (as stated in change.md line 19)
- `relationships-{domain}.md` (as stated in build-relationships.md line 6)

A: domain-{domain-name}.md

## 2. Output File Location

**Question**: Where should the generated files be placed?

- In `uspecs/` directory (as build-relationships.md suggests: `uspecs/relationships-{domain}.md`)
- Or somewhere else?

A: uspecs/domain-{domain-name}.md

## 3. Template Format Mismatch

The `example-context.md` template shows a different structure than `build-relationships.md`:

**example-context.md** has:

- Domain header
- Participants section (Roles and External systems)
- Contexts section
- Context map
- Relationships for context sections

**build-relationships.md** template has:

- Domain relationships header
- Context map
- Individual context sections with diagrams

**Question**: Which template structure should the bash script follow?

A: `example-context.md`

## 4. Integration with uspecs.sh

The principles state:

> main.md calls uspecs.sh
> uspecs.sh calls build-rels.sh

**Questions**:

- What command should be added to uspecs.sh? (e.g., `uspecs domains build`)
- What parameters should build-rels.sh accept?
- Should it read the contexts file path from conf.md or accept it as a parameter?

A: uspecs domains build

## 5. YAML Parsing in Bash

**Question**: How should the bash script parse the YAML file?

- Use `yq` (YAML processor)?
- Use `python` with PyYAML?
- Use another tool?
- Should we assume a specific tool is available, or should the script check for dependencies?

A: Parse the YAML directly with bash using `grep`, `sed`, and `awk`

## 6. Mermaid Diagram Generation Logic

**Questions**:

- How should the script determine which relationships to show in each context's diagram?
- For context-to-context relationships, should both contexts show the relationship, or only the "current" context?
- How should the script handle "safe names" for Mermaid node IDs (e.g., converting "Change Manager" to "SafeActorName")?

A:

- all relationships with given context (since we are talking about `## Relationships for context: {context-name}`)
- Show in all related contexts (if A→B, show in both A's section and B's section)?
- replace spaces and non-alphanumeric characters with hyphens

## 7. Arrow Direction Rules

The build-relationships.md specifies arrow direction rules for asymmetric relationships. **Question**: Should the bash script implement these rules, or should it use a simpler approach (e.g., always show relationships as they appear in the YAML)?

A: as they appear in the YAML, it is always upstream -> downstream

## 8. Relationship to Actors

**Question**: How should the script identify which actors (roles/systems) are related to each context? The YAML only has a flat `relationships` array - should the script:

- Filter relationships where one participant is the context and the other is a role/system?
- Include all relationships involving the context?

A:

- For each context's diagram, include all relationships where that context is a participant (whether the other participant is another context, a role, or a system)

## 9. Deprecation of build-relationships.md

The principles state:

> we do not need build-relationships.md anymore

**Question**: Should build-relationships.md be:

- Deleted entirely?
- Kept for reference but marked as deprecated?
- Replaced with documentation about the new script?

A: deleted entirely

## 10. Error Handling

**Question**: What error conditions should the script handle?

- Missing contexts.yml file
- Invalid YAML format
- Empty domains
- Missing required fields
- Should it fail fast or continue with warnings?

A: fail fast
