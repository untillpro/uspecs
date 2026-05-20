# Complete to-do items

## data

- Complete ONLY the to-do items listed below (from `${change_folder}/${impl_file}`):

```markdown
${unchecked_items}
```

- Do not perform work outside this list
- Stop on the ${review_item} item -- it is a human review checkpoint, do not implement it (?has_review)
- If possible process items in parallel using subagents
- Immediately after completing each item, check it as completed in the file
- After completing all items, inform the user that the review checkpoint has been reached (?has_review)
- After completing all items (?chain_self_review)
  - Inform the user that a self-review pass will now run, scoped to the work just completed (?chain_self_review)
  - Silently evaluate whether the completed changes touch concurrency-sensitive code paths; only if they do, tell the user and add `--concurrency` to the invocation below.(?chain_self_review_construction)
  - Invoke `bash bin/softeng.sh self-review --type ${self_review_type} --stage A {optional --concurrency}` (?chain_self_review)
