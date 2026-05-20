# Decisions

## Uncertainty: where does "create `## How`" fit in the existing uimpl priority cascade

Decision: Create How only when no planning sections exist yet

- Pros: keeps the "todos first" branch untouched; gates How on the pre-planning state of the file, so it captures decisions before any section work begins; once any planning section exists the existing cascade resumes unchanged, avoiding regressions
- Cons: a change folder whose planning has already started never gets a How prompt from `uimpl` -- engineers must add it manually if they want one retroactively
- Confidence: user-provided

Alternatives:

1. First step of the no-todos section cascade (before Domain specifications)
   - Pros: minimal change to the decision tree; reuses the same `how_exists` gating as other sections
   - Cons: How would be offered even after planning sections already exist, contradicting "decisions captured up-front"
   - Confidence: high
2. Highest priority -- before todos and before the section cascade
   - Pros: forces the agent to capture intent before any other work
   - Cons: breaks the current "todos first" invariant; surprises engineers mid-implementation
   - Confidence: medium
3. After the cascade -- only if every other section exists
   - Pros: zero impact on existing flows
   - Cons: defeats the goal of using How to steer the implementation
   - Confidence: low

## Uncertainty: in which file does uimpl create the `## How` section

Decision: Always append to `change.md` (match existing `artdef_change_how.md`)

- Pros: zero change to the existing `artdef_change_how.md` artifact, which already says "Append to the Change File a `## How` section..."; preserves the framing that `## How` belongs to the change request itself rather than the implementation plan; the change request remains the source of decisions even after `impl.md` exists
- Cons: introduces a single exception to the otherwise uniform "uimpl writes to the Implementation Plan File" rule -- specs and implementation must call this out explicitly
- Confidence: user-provided

Alternatives:

1. Append to the Implementation Plan File (`impl.md` if it exists, else `change.md`)
   - Pros: uniform with the rest of the uimpl cascade; resilient to manual `impl.md` creation
   - Cons: contradicts the existing `artdef_change_how.md` wording; would require reworking the artdef or parameterising the file
   - Confidence: high
2. Append to `change.md` only when `impl.md` does not exist; otherwise skip How entirely
   - Pros: avoids touching `change.md` after implementation has started
   - Cons: confusing edge case when `impl.md` exists with no planning sections (e.g., created manually)
   - Confidence: low

## Uncertainty: how the new behaviour is expressed in uimpl.feature

Decision: Add a new standalone scenario before the existing "No unchecked to-do items" Scenario Outline

- Pros: keeps the existing Scenario Outline rows intact; new behaviour is described in one place with its own preconditions and `--plan` opt-out scenario; small, reviewable diff
- Cons: two scenarios share the "no unchecked to-do items" precondition, slightly fragmenting the no-todos flow across two scenarios
- Confidence: user-provided

Alternatives:

1. New row in the existing "No unchecked to-do items" Scenario Outline
   - Pros: cascade order expressed in a single table
   - Cons: the How step has additional preconditions (no other planning section exists, `--plan` not set) that don't fit the table shape
   - Confidence: low
2. New top-level Rule block "How section creation" parallel to "Implementation Folder is identified"
   - Pros: clearly separates the new behaviour
   - Cons: duplicates the existing Rule background; adds spec surface without clear scope delineation
   - Confidence: low
