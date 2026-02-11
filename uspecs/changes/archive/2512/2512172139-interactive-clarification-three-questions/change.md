# Change: Interactive clarification with three questions

- archived_at: 2025-12-17T21:16:09Z
- registered_at: 2025-12-17T20:33:48Z
- change_id: 251217-interactive-clarification-three-questions
- baseline: 78f2714c9ae7ef0254c01f826e214bdf40cc90bd

## Problem

When creating or processing changes, ambiguities and uncertainties often arise that require clarification. Currently, there is no structured mechanism to identify unclear aspects, ask targeted questions with suggested solutions, and integrate the answers back into the change documentation. This leads to incomplete or ambiguous change specifications.

## Proposal

Add a clarify.md action triggered by AGENTS.md that enables interactive clarification during change processing. The action will:

- Identify three key ambiguities or uncertainties in any files within the Active Change Folder and subfolders
- Ask three questions with suggested solutions
- Integrate answers back into change files:
  - If question is about fixing ambiguity, the ambiguity is fixed in the appropriate files (change.md, design.md, fd.md, plan.md, or any other file in Active Change Folder)
  - If question is about choice or uncertainty, the answer is integrated into decisions.md

## Clarifications

### Triggering mechanism

- Trigger keyword: "ask questions"
- Added to AGENTS.md triggering instructions section
- User explicitly invokes it when needed

### When it executes

- Manual invocation by user saying "ask questions"
- Can be invoked at any stage when working with a change

### Scope of files to update

- Any file in Active Change Folder and its subfolders
- Includes: change.md, design.md, fd.md, plan.md, and any other files

### decisions.md template

- Add decisions.md template section to uspecs/u/templates.md
- decisions.md file is created in Active Change Folder when needed
- Structure follows decision documentation pattern (decision title, rationale, alternatives considered)

### Relationship to existing td.md clarification

- Separate mechanism, independent from existing td.md clarification
- General-purpose clarification tool, not specific to technical design
- Can be used at any stage of change processing
