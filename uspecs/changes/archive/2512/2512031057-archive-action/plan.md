# Implementation plan: Archive action should embrace all links into backticks

Change: `[change.md](change.md)`

## Files modification

### Create archive action documentation

- [x] create: `[archive.md](../../../.uspecs/actions/archive.md)`
  - Document the archive action process
  - Step 1: Read project structure rules to find active changes folder
  - Step 2: Identify change to archive (from context or ask user)
  - Step 3: Process all markdown files in the change folder
  - Step 4: Convert all markdown links to backtick-wrapped format using sed
  - Step 5: Move the change folder to archive
  - Include sed command examples for link conversion
  - Include fallback approach for systems without sed
  - Format: `` `[text](url)` ``
  - Skip links already wrapped in backticks (avoid double-wrapping)
  - Process ALL markdown files (*.md) in the change folder

### Update AGENTS.md with archive action trigger

- [x] update: `[AGENTS.md](../../../AGENTS.md)`
  - Add triggering instruction for archive action
  - Insert after the "Apply" instruction line
  - Format: `- Always load '@/.uspecs/actions/archive.md' and follow the instructions there when the request sounds like "Archive change"`
  - Place inside the `<!-- seeai:triggering_instructions:begin -->` and `<!-- seeai:triggering_instructions:end -->` section
  