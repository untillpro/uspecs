---
change_id: 2605271501-upr-pr-body-relative-links
type: fix
scope: softeng
issue_url: https://github.com/untillpro/uspecs/issues/112
---

# Change request: Fix broken relative links in PR body

Resolves:

- [112: upr: PR body contains relative file links that 404 on the PR page](https://github.com/untillpro/uspecs/issues/112)

## Why

Reviewers cannot navigate to referenced source files from the PR page because every `../../../...` link rendered in the PR body resolves against the PR URL and 404s. The change request restores trust in the rendered references so reviewers can identify the scope of the change without leaving GitHub.

## What

Symptom: Relative file links copied from `change.md` into the PR body render as clickable links that 404 on the GitHub PR page.

```text
author runs upr
      |
      v
cmd_action_upr reads change.md
      |
      v
awk pass composes PR body         <-- fault: emits ../../../... link targets verbatim
      |
      v
gh pr create publishes body
      |
      v
reviewer clicks link on PR page -> GitHub 404   (symptom)
```

Corrected behavior: The PR body composer rewrites relative file links by stripping the leading `(../)+` prefix, prepending a single `/`, and wrapping the whole `[text](path)` literal in backticks so it renders as inert monospace text on the PR page (no broken hyperlink, repo-root path visible to the reader).

Example:

```markdown
- before: [authentication contract](../../../../../pkg/iauthnz/authn-interface.go)
- after:  `[authentication contract](/pkg/iauthnz/authn-interface.go)`
```

## How

Decisions:

- Rewrite relative file links in the PR body: strip the leading `(../)+` prefix, prepend a single `/`, and wrap the whole `[text](path)` literal in backticks so it renders as inert monospace text on the PR page (no click-through, no 404).
- Implement the transform as a reusable helper `md_defang_relative_link` in `bin/_lib/utils.sh` (`md_` prefix groups Markdown helpers; "defang" per security-tooling convention for making a URL inert).
- Invoke the helper from `cmd_action_upr` as one pass between the existing awk pass and the truncation guards.
- Reuse the awk pass's fenced-code tracking to skip rewriting inside fenced blocks; also skip absolute URLs (`http://`, `https://`, `mailto:`), anchors (`#...`), already-root-absolute (`/...`), and same-folder targets (`./...` or bare filename).
- Extend the existing `Construct PR body` scenario outline with a link-handling rule rather than introducing a new scenario.

Out of scope:

- Deriving `owner/repo` or pinning to a branch/SHA for absolute blob URLs.
- Validating that link targets actually exist in the repository.
- Click-through navigation from the PR page (reviewers copy the path or use GitHub's file finder).

References:

- [PR body composition step](../../../../../bin/softeng.sh)
- [shared utility helpers](../../../../../bin/_lib/utils.sh)
- [upr scenario outline](../../../../../uspecs/specs/prod/softeng/upr.feature)
- [upr action tests](../../../../../tests/sys/softeng.sh-action-upr.bats)
- [GitHub: autolinked references and relative paths](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/autolinked-references-and-urls)

## Functional design

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: "Construct PR body" scenario outline -> added a step asserting that relative file links in pr_body are defanged (leading `(../)+` stripped, prepended with `/`, whole `[text](path)` wrapped in backticks)
  - add: new "PR body link handling" scenario outline with rows covering rewritten relative links and link inputs that must be left unchanged (absolute URL, `mailto:`, anchor, root-absolute, `./...`, bare filename, fenced-code)

## Construction

- [x] update: [unit/utils-md.bats](../../../../../tests/unit/utils-md.bats)
  - add: unit tests for `md_defang_relative_link` covering each input class from the `PR body link handling` example rows (rewritten relative, archived-depth, http/https/mailto, anchor, root-absolute, `./`, bare filename, fenced-code, escape-the-repo)

- [x] update: [sys/softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - add: integration test asserting that `upr` emits a defanged link in `pr_body` when `change.md` body contains `[label](../../../../../bin/softeng.sh)`
  - add: integration test asserting that a link inside a fenced code block in `change.md` is left untouched in `pr_body`

- [x] update: [_lib/utils.sh](../../../../../bin/_lib/utils.sh)
  - add: `md_defang_relative_link` function that reads stdin and writes the transformed Markdown to stdout
  - rule: outside fenced code blocks, for each `[text](path)` literal where `path` starts with `../`, strip the leading `(../)+` segments, prepend a single `/`, and wrap the whole literal in backticks
  - skip: lines inside fenced code blocks; targets starting with `http://`, `https://`, `mailto:`, `#`, `/`, `./`, or no path separator (bare filename)

- [x] update: [softeng.sh](../../../../../bin/softeng.sh)
  - update: `cmd_action_upr` to pipe `$pr_body_file` through `md_defang_relative_link` between the existing awk pass and the truncation guards
