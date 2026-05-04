# Next steps after PR creation

## data

PR has been created: ${pr_url}

To restore branch to its pre-squash state, if needed:

```text
# Run from the PR branch with a clean working tree:
git reset --keep ${pre_push_head}
git push --force-with-lease
```

Next steps:

- Fix any issues raised during review
- Run `umergepr` once the PR is approved and ready to merge
