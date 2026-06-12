# Chain self-review

<!-- markdownlint-disable-->

## data

After authoring the work above: (?chain_self_review)

- Inform the user that a self-review pass will now run, scoped to the work just completed (?chain_self_review)
- Invoke `bash "${softeng_sh}" self-review --type ${self_review_type} --stage A -b ${self_review_budget}` (?chain_self_review)(?self_review_budget)
- Invoke `bash "${softeng_sh}" self-review --type ${self_review_type} --stage A` (?chain_self_review)(?!self_review_budget)
