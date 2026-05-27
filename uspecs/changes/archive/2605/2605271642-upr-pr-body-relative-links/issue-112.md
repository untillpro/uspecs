# upr: PR body contains relative file links that 404 on the PR page

- URL: https://github.com/untillpro/uspecs/issues/112
- ID: `#112`
- State: open
- Author: @maxim-ge
- Labels: none

## Symptom

PRs created by `upr` show broken links in the rendered PR body. Any reference of the form `[text](../../../../../some/path)` in `change.md` appears as a clickable link on the PR page, but the target is resolved by GitHub against the PR URL (`/{owner}/{repo}/pull/{N}`) walking up the path - producing a 404.

Example from a recently created PR header:

```markdown
References:

- [authentication contract](../../../../../pkg/iauthnz/authn-interface.go)
- [authentication request and principal types](../../../../../pkg/iauthnz/authn-types.go)
- [principal token payload types](../../../../../pkg/itokens-payloads/types.go)
- [user and device API handlers](../../../../../pkg/router/impl_apiv2.go)
```

All links above 404 when clicked on the PR page.

## Root cause

`cmd_action_upr` in `bin/softeng.sh` composes the PR body from `change.md` with an `awk` pass that handles only:

- YAML frontmatter fencing (wraps `---` block in `` ```yaml ``)
- selection of body content from the first top-level `##` section
- fenced-code tracking so headings inside fences do not start a new section
- 40-line / 4000-char truncation guards

It does not transform link targets. Relative paths in `change.md` are computed from the Change Folder's on-disk location (e.g. `uspecs/changes/{wcf}/change.md`, or one level deeper after archiving), so they look like `../../../...`. Those paths are valid locally but invalid on the GitHub PR page, where there is no enclosing folder context.

The affected step:

```bash
# bin/softeng.sh, cmd_action_upr
awk '
    ...
    NR==1 && /^---$/ { in_frontmatter=1; print "```yaml"; next }
    in_frontmatter && /^---$/ { in_frontmatter=0; print "```"; next }
    ...
    if (!in_fence && /^## /) { in_body = 1 }
    if (in_body) print
' "$change_file" > "$pr_body_file"
```

## Reproduction

- Run `uchange` to create a WCF, add a `## How` / References section with a relative link such as `[foo](../../../../../bin/softeng.sh)`.
- Run `upr`.
- Open the created PR on GitHub and click any of the relative links in the body - 404.

## Why root-relative or branch-pinned URLs are not a drop-in solution

- Repo-root-relative (`/pkg/...`): GitHub resolves these against the **default branch**, so files added by the PR (not yet on the base branch) still 404 until merge. Acceptable only for already-existing files.
- Absolute blob URLs (`https://github.com/{owner}/{repo}/blob/{ref}/...`): correct, but require deriving `owner/repo` (extra `gh`/`git remote` call) and picking a `ref` - branch name (stale after deletion) or post-squash SHA (more robust, less readable). Adds non-trivial code and test surface.

## Suggested fixes (pick one)

1. Wrap relative links in inline code and normalize the path to repo-root-relative (recommended)
   - Transform: `[authentication contract](../../../../../pkg/iauthnz/authn-interface.go)` -> `` `[authentication contract](pkg/iauthnz/authn-interface.go)` ``
   - One regex pass after the awk step; strips the leading `(../)+` and wraps the whole `[...](...)` literal in backticks so it renders as monospace text, not a hyperlink.
   - Skips: absolute URLs (`http://`, `https://`, `mailto:`), anchors (`#...`), root-absolute (`/...`), same-folder targets (`./...`, bare filename), and anything inside fenced code blocks (existing `in_fence` tracking).
   - Pros: no `gh`/`git remote` dependency, no branch/SHA logic, robust for files added by the PR, tiny diff, easy to test.
   - Cons: no click-through navigation; reviewers copy the path or use GitHub's file finder.

2. Rewrite relative links to absolute blob URLs pinned to the PR head branch (`https://github.com/{owner}/{repo}/blob/{current_branch}/{path}`).
   - Pros: clickable links that resolve to the exact code under review, including newly added files.
   - Cons: needs `owner/repo` derivation; links go stale after branch deletion (mitigated by pinning to the post-squash SHA instead, at the cost of readability).

3. Hybrid: per-link, root-relative when the target exists on `default_branch`, fallback to variant 1 (backtick-wrapped) otherwise.
   - Pros: click-through for unchanged refs, readable text for new files.
   - Cons: more moving parts and mixed link styles in one body.

Variant 1 is the smallest, safest, and the one matching prior discussion.

## Scope

- spec: `uspecs/specs/prod/softeng/upr.feature` - extend the "Construct PR body" scenario with a link-handling rule.
- impl: `bin/softeng.sh#cmd_action_upr` - one regex step between the awk pass and the truncation guards.
- tests: `tests/sys/softeng.sh-action-upr.bats` - add cases for relative link (rewritten), absolute URL (unchanged), anchor (unchanged), link inside fenced code (unchanged), archived-depth `../../../../../` prefix (normalized), target escaping the repo (left untouched).

## References

- Code: `bin/softeng.sh#cmd_action_upr` (PR body composition, ~lines 1647-1700)
- Spec: `uspecs/specs/prod/softeng/upr.feature` ("Construct PR body" scenario)
- Tests: `tests/sys/softeng.sh-action-upr.bats`
- Related historical change: `uspecs/changes/archive/2601/2601311837-archive-link-prefix/change.md` (replaced backtick-wrapping with `../` prefixing for the on-disk archive case - different context, different trade-off)
