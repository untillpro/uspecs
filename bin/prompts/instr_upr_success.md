# Next steps after PR creation

## data

PR has been created: ${pr_url}

The branch was squashed and force-pushed. Show the user this exact command they can run to restore the pre-squash state if needed:

```text
# Run from the PR branch with a clean working tree:
git reset --keep ${pre_push_head}
git push --force-with-lease
```

Next steps:

- Fix any issues raised during review
- Run `umergepr` once the PR is approved and ready to merge
