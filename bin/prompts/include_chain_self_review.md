# Chain self-review

<!-- markdownlint-disable-->

## data

After authoring the work above: (?chain_self_review)

- Inform the user that a self-review pass will now run, scoped to the work just completed (?chain_self_review)
- Silently evaluate whether the completed changes touch concurrency-sensitive code paths; only if they do, tell the user and add `--concurrency` to the invocation below. (?chain_self_review_construction)
- Invoke `bash "${softeng_sh}" self-review --type ${self_review_type} --stage A -b ${self_review_budget}` (?chain_self_review)(?self_review_budget)
- Invoke `bash "${softeng_sh}" self-review --type ${self_review_type} --stage A` (?chain_self_review)(?!self_review_budget)
