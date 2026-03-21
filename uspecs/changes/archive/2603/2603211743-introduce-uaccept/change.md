---
registered_at: 2026-03-12T07:00:31Z
change_id: 2603120700-introduce-uaccept
baseline: c9614d33d1f10184c96e64781e1fe3b439938e6f
archived_at: 2026-03-21T17:43:24Z
---

# Change request: Introduce uaccept action

## Why

After a PR is reviewed and approved, finalizing it requires several manual steps: archiving all active changes, merging the PR with squash, and cleaning up local branches. Automating this via a dedicated `uaccept` action ensures the process is always executed consistently and reduces friction for the Engineer.

## What

### Script-driven action dispatch

Actions `upr` and `uaccept` are executed via `uspecs.sh prompt {keyword}`. The script handles all logic: inspects repo state (branch, Working Change Folder, PR status), validates preconditions, performs git/gh operations, and outputs instructions for the agent to relay to Engineer. The agent does not read change.md, compute titles, or make decisions -- it only runs the script and displays the output.

AGENTS.md and CLAUDE.md are updated to dispatch these keywords through the script instead of static action files. The `actn-upr.md` and `actn-uaccept.md` files are removed.

### upr

Implement `uspecs.sh prompt upr` -- create a PR from the current branch.

- Validate preconditions, detect Working Change Folder, archive if active
- Read change.md (frontmatter and heading), compute pr_title, commit_message, see_details_line
- Squash branch, force-push, open PR creation in browser
- Output next-steps prompt for the agent
- See upr.feature for scenarios and definitions

### uaccept

Implement `uspecs.sh prompt uaccept` -- accept a PR associated with the current branch.

- Validate preconditions, detect Working Change Folder
- Handle PR states: not found, OPEN, not OPEN
- Archive Working Change Folder if active, attempt merge, handle failure
- Output result/instructions for the agent
- See uaccept.feature for scenarios and details

### Deprecated subcommands

Existing `pr preflight`, `pr create`, and `status ispr` subcommands in uspecs.sh are deprecated. They remain in the script for now but are not used by the new `prompt` dispatch. They will be removed in a later change.

### System tests

Add system tests covering the full flow of `prompt upr` and `prompt uaccept`, including edge cases (e.g., merge conflicts, missing PR, active changes).

### Implementation details

- All user-facing output is kept in `u/scripts/prompts.md` as named sections
  - `utils.sh#section_templ()` is used to read and format prompt sections with variable substitution
  - Each output branch has its own section (e.g., `upr_success`, `uaccept_success`, `uaccept_no_pr`, `uaccept_not_open`, `uaccept_merge_failed`)
  - This keeps all user-facing text in one place, separate from script logic

## History

- 260321, before deep rethink
  - https://github.com/untillpro/uspecs/blob/59ae5fec30f2368e13be898ab0861e6f3cdae70f/uspecs/changes/2603120700-introduce-uaccept/change.md
  - https://github.com/untillpro/uspecs/blob/1f15a2b741ad56905f43f9ac4b65446983e6e255/uspecs/changes/2603120700-introduce-uaccept/impl.md
