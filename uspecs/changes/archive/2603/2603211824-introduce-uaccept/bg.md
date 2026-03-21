# Background

## Links

- https://claude.ai/chat/3b6882d3-33dc-4e17-8146-7cee7769ad91
  - git reset --soft "$(git merge-base HEAD origin/main)"
  - git branch --show-current
  - git rev-parse --short HEAD
- https://cli.github.com/manual/gh_pr
  - gh pr create --repo https://github.com/untillpro/inv-pull --web --title "[123] pr text" --body "Closes#123"
  - gh pr view pr2 --repo https://github.com/untillpro/inv-pull --json state -q ".state"
    - OPEN, CLOSED, MERGED
  - gh pr merge -s
- https://docs.gitlab.com/cli/mr/create/
