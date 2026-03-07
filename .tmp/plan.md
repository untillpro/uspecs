# Plan

## cmd_apply (--pr flow)

- remember current branch, set trap to restore it on exit
- call pr.sh ffdefault (leaves repo on default branch)
- reload uspecs.yml and recheck if update/upgrade is still needed
  - if already up to date, exit cleanly
- show plan, confirm
- create PR branch from default branch (prbranch)
- apply changes, commit, push, open PR
- trap restores original branch

## pr.sh ffdefault

- remove switch-back logic
- always leave repo on the default branch after fast-forward

## Implementation plan

- [x] pr.sh ffdefault: remove switch-back logic, always leave on default branch
- [x] pr.sh ffdefault: update doc comment
- [x] cmd_apply: remember current branch before ffdefault, set trap to restore it on exit
- [x] cmd_apply: move ffdefault call before load_config/recheck block
- [x] cmd_apply: recheck after ffdefault covers both alpha (commit) and stable (version) cases
