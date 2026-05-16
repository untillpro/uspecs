---
registered_at: 2026-05-16T15:58:51Z
change_id: 2605161558-add-conventional-type-and-scope
type: feat
baseline: db08cfe10370ee4ace28271d4c835a429cb08120
archived_at: 2026-05-16T18:51:26Z
---

# Change request: Introduce Conventional Commits type and scope in uchange and PR

## Why

Pull request titles and squash commit subjects currently carry only a free-form change title (optionally prefixed by an issue id). This makes commit history harder to scan, filter, and feed into release tooling. Adopting the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) `type(scope): description` convention gives every change a machine-readable classification, ties scope to existing domain/context structure already present under `uspecs/specs/`, and keeps PR titles and commit subjects in lockstep with the change request.

## What

Commit should look like:

```text
feat(softeng): Enforce SELECT ACL on fields in VSQL WHERE clause [AIR-3289]

See change.md for details
Closes #AIR-3289
```

PR title:

```text
feat(softeng): Enforce SELECT ACL on fields in VSQL WHERE clause [AIR-3289]
```

- Store `type`, `scope`, and `breaking` as YAML frontmatter fields in `change.md`. `upr` reads them from frontmatter (via the existing `md_read_frontmatter_field` helper) to compose the PR title and commit subject. The heading stays human-readable.

- Allowed types follow Conventional Commits: `feat`, `fix`, `build`, `chore`, `ci`, `docs`, `perf`, `refactor`, `revert`, `style`, `test`. Breaking changes are marked by a separate `breaking: true` frontmatter field (rendered as a trailing `!` before the `:` in the subject, after the scope parens if present); `type:` itself stays clean (e.g. `feat`, not `feat!`). `breaking` is written only when true; the field is omitted otherwise (default is `false`).

- Scope is derived from `uspecs/specs/{domain}` and `uspecs/specs/{domain}/{context}` names when the specs folder exists, free-form otherwise. Multiple scopes are comma-separated in a single `scope:` frontmatter field, e.g. `scope: softeng,devops`. Scope is optional and may be omitted entirely.

- The allowed types list lives in exactly one place: `scripts/templates/actions/uchange.yaml` (dispatch-time surface). At authoring time the `type:` field is already in the frontmatter (written verbatim from `--type` by `softeng.sh`), so the authoring-time prompt does not repeat the list. The authoring-time prompt fragment (extended into `instr_uchange.md` or a sibling fragment) covers scope derivation and breaking criteria only -- both are set later by the agent during Construction. The scope-from-specs branch of the guidance is gated on the existence of `uspecs/specs/`.

- The dispatcher template `scripts/templates/actions/uchange.yaml` gains a `--type` derivation rule (parallel to the existing `--kebab-name` rule) and lists `--type <type>` as required in `options`. The `<!-- uspecs:begin -->`/`<!-- uspecs:end -->` block in `AGENTS.md` and `CLAUDE.md` is changed from inlining the uchange rules to referencing `scripts/templates/actions/uchange.yaml` directly -- mirroring the existing `uclarify` reference pattern. AGENTS.md / CLAUDE.md collapse the per-`uchange` bullet list to a single rule: when user input starts with `uchange [options] {other-input}`, read the `raw_text` block in `scripts/templates/actions/uchange.yaml` and follow its instructions, treating `{{dispatch}}` as `run bash bin/softeng.sh action uchange {options}`. This makes `uchange.yaml` the single source of truth for the dispatch-time rule, with no duplication anywhere else. Other actions (`upr`, `umergepr`, `uimpl`, `uarchive`, `usync`, `uversion`) stay inlined for now; generalizing the reference pattern across all actions is left as a follow-up change.

## How

Decisions:

- New `--type <type>` option for `uchange`, required. The value is written verbatim into the `type:` frontmatter field of the newly created `change.md`. `softeng.sh` does not validate the value; the allowed list is enforced solely by the prompt instructions given to the AI Agent.

- The `scope:` and `breaking:` frontmatter fields are added by the agent always and only when it writes the Construction section, based on the references and changes planned at that point. `scope:` is written when at least one scope applies; `breaking:` is written only when the change is breaking (i.e. only ever as `breaking: true`). The Construction section may be written during `uchange` (when the impl cascade reaches it in the same flow) or later during `uimpl`. If no Construction section is produced (e.g. `--no-impl`), neither field is set and `upr` composes the title without a scope and without `!`.

- `cmd_action_upr` reads `type`, `scope`, and `breaking` from `change.md` frontmatter and composes `pr_title` and the pre-squash `commit_message`. The previous "text after `:` in the heading" rule still produces `change_title` from the human-readable heading. PR title equals the pre-squash commit subject.

- If `type:` is absent from `change.md` frontmatter, `cmd_action_upr` exits with a non-zero status and an error message directing the AI Agent to (a) read the allowed Conventional Commits types from the `uchange` dispatch instructions (the same source the agent consulted at `uchange` time -- in installed plugins this is the rendered `uchange` skill/command, in source this is `scripts/templates/actions/uchange.yaml`) and (b) show the list to the user with a prompt to add `type: <value>` to `change.md` frontmatter. `softeng.sh` itself does not list the types -- the user has no path to the yaml in plugin contexts, so the agent acts as the bridge. No fallback, no default. Pre-existing in-flight change folders -- including this one -- must have `type:` added manually before `upr` can run against them. `scope:` and `breaking:` remain optional (absent means "no scope" and "not breaking").

- Subject template: `<type>[(<scope>)][!]: <change_title>[ [<issue_id>]]` -- parens around `<scope>` only when scope is present; `!` only when `breaking: true`; the `[<issue_id>]` suffix (preceded by a single space) only when `issue_url` is present.

- Pre-squash commit body (after one blank line, in this order, omitting absent lines): `See change.md for details`, then `Closes #<issue_id>` (when `issue_url` is present). The `Closes` trailer comes last to follow the Git convention that machine-readable trailers cluster at the bottom.

- `pr_body` continues to use the existing rule (YAML frontmatter fenced as `yaml`, followed by the Why / What / How sections of `change.md`).

- `breaking: true` criteria (conservative shape rule): set only when an existing user-facing contract is removed or changed in an incompatible way. The "contract" covers (a) code APIs / CLI surfaces -- function or command signatures, parameter lists, return types, behavior on previously valid inputs; and (b) UI -- existing screens or workflows removed or restructured so a previously valid user path no longer works, or inputs/outputs of existing controls changed incompatibly (renamed/removed fields, tightened validation, etc.). Additive changes (new screens, new optional parameters, new commands or flags) are never breaking.

References:

- [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)

## Functional design

- [x] update: [softeng/uchange.feature](../../../../specs/prod/softeng/uchange.feature)
  - update: `Rule: Core behavior` "No options" outline to treat `--type` as part of the basic invocation (mandatory, same status as the implicit `--kebab-name`); add a `Then` line that the `type:` frontmatter field equals the supplied value
  - add: under `Rule: Edge cases`, scenario for missing `--type` -> error from `softeng.sh` and no change request created

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - update: "No PR for current branch: PR title and commit message" scenario outline to use the new subject template `<type>[(<scope>)][!]: <change_title>[ [<issue_id>]]`
  - update: `message_format` examples so the commit body uses trailers in order `See change.md for details`, then `Closes #<issue_id>` (with the `Closes` line omitted when there is no `issue_url`)
  - update: outline examples to also vary `scope` (absent / single / comma-separated) and `breaking` (absent / `true`), so all permutations of `(<scope>)` and `!` in the subject are covered
  - add: edge-case scenario "change.md frontmatter is missing `type:`" -> `upr` exits with an error pointing at the allowed list and does not create the PR

- [x] update: [softeng/uimpl.feature](../../../../specs/prod/softeng/uimpl.feature)
  - update: "Construction section does not exist and it is needed" scenario to note that, when the Construction section is created, `scope:` is written to `change.md` frontmatter (when at least one scope applies) and `breaking: true` is written when the change is breaking (per the conservative shape rule, including UI); both fields are omitted otherwise

## Technical design

Not needed

## Construction

### Tests

- [x] update: [tests/sys/softeng.sh-action-uchange.bats](../../../../../tests/sys/softeng.sh-action-uchange.bats)
  - update: existing `No options` / mandatory-options scenarios to pass `--type feat` (or another type) and assert `type: <value>` appears in the `change_frontmatter` artifact body
  - add: test for missing `--type` -> non-zero exit and error message mentioning required `--type` (softeng.sh does not enumerate allowed types; the agent's authoring-time dispatch instructions cover the list)

- [x] update: [tests/sys/softeng.sh-action-upr.bats](../../../../../tests/sys/softeng.sh-action-upr.bats)
  - update: `_make_upr_change` helper (or callers) to write `type:` (and optionally `scope:` / `breaking:`) into the seeded frontmatter
  - update: existing PR title / commit message tests so the asserted `pr_title` and pre-squash `commit_message` use the new subject template `<type>[(<scope>)][!]: <change_title>[ [<issue_id>]]` and the body order `See change.md for details` then optional `Closes #<issue_id>`
  - add: tests for the example permutations from `upr.feature` -- type-only; type + single scope; type + comma-separated scope + issue_url; type + scope + breaking + issue_url; type + breaking-only
  - add: test for missing `type:` frontmatter -> non-zero exit and error message directing the AI Agent to read allowed types from the uchange dispatch instructions and present them to the user; assert no PR is created and the error does NOT enumerate type values inline

### Scripts

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - update: `cmd_action_uchange` -- add `--type <type>` parsing, required (error when missing, mirroring the existing `--kebab-name is required` pattern); pass the value through to `_uchange_compute`
  - update: `_uchange_compute` -- accept `type` parameter and emit `type: <value>` as a frontmatter field (placed after `change_id`, before optional `issue_url`)
  - update: `cmd_action_upr` -- read `type`, `scope`, `breaking` from `change.md` frontmatter via `md_read_frontmatter_field`; compose `pr_title` and pre-squash `commit_message` per the subject template `<type>[(<scope>)][!]: <change_title>[ [<issue_id>]]`; compose body in order `See change.md for details`, then `Closes #<issue_id>` when `issue_url` is present
  - add: in `cmd_action_upr`, hard-fail (non-zero exit) when `type:` is absent from frontmatter; the error message directs the AI Agent to read the allowed Conventional Commits types from the `uchange` dispatch instructions and show them to the user with a prompt to add `type: <value>` to `change.md` -- `softeng.sh` itself does not enumerate the types; PR is not created

- [x] update: [templates/actions/uchange.yaml](../../../../../scripts/templates/actions/uchange.yaml)
  - add: `--type <type>` derivation rule under `raw_text` -- agent infers a Conventional Commits type from the change description; lists allowed values `feat`, `fix`, `build`, `chore`, `ci`, `docs`, `perf`, `refactor`, `revert`, `style`, `test`; brief one-line guidance per type
  - update: `options` to include `--type <type>` (required) alongside the existing `--kebab-name <name>` (required)

### Prompts and skills

- [x] update: [prompts/include_impl_sections.md](../../../../../bin/prompts/include_impl_sections.md)
  - add: sub-bullets under the existing Construction line that instruct the agent to set `scope:` and `breaking:` in `change.md` frontmatter after authoring the Construction section. The sub-bullets are gated by `(?constr_maybe)` so they appear only when Construction is being added; the `scope:` rule is split by `(?domains_defined)` / `(?!domains_defined)` to choose between "derive from `uspecs/specs/{domain}` / `{domain}/{context}` folder names" and "free-form scope from the code area touched"; the `breaking:` rule is unconditional within the Construction gate

- [x] update: [bin/softeng.sh](../../../../../bin/softeng.sh)
  - add: `domains_defined` detection in `cmd_action_uimpl` -- set to `"1"` when at least one `uspecs/specs/{domain}/domain.md` file exists; expose it in the `impl_vars` map so `include_impl_sections.md` can gate on it via `(?domains_defined)` / `(?!domains_defined)`

### Dispatcher

- [x] update: [AGENTS.md](../../../../../AGENTS.md)
  - update: inside the `<!-- uspecs:begin -->`/`<!-- uspecs:end -->` block, replace the inlined `For uchange` bullet sub-list with a single rule (mirroring the existing `uclarify` reference pattern): when user input starts with `uchange [options] {other-input}`, read the `raw_text` block in `scripts/templates/actions/uchange.yaml` and follow its instructions, treating `{{dispatch}}` as `run bash bin/softeng.sh action uchange {options}`; remove `uchange` from the inlined `Available commands` list (it now has its own rule above the generic block)

- [x] update: [CLAUDE.md](../../../../../CLAUDE.md)
  - update: same change as in `AGENTS.md` -- inside the `<!-- uspecs:begin -->`/`<!-- uspecs:end -->` block, replace the inlined `For uchange` sub-list with the reference rule pointing at `scripts/templates/actions/uchange.yaml`; remove `uchange` from the inlined `Available commands` list

### Migration

- [x] update: [change.md](change.md)
  - add: `type: feat` to the YAML frontmatter of this change folder so `upr` can run against it once the new behavior is in place (this change introduces a user-facing CLI option, so `feat` is the appropriate Conventional Commits type)

## Quick start

After this change, `uchange` requires `--type <type>`. The agent fills it in automatically from the description; users invoking the dispatcher directly must supply it:

```bash
bash bin/softeng.sh action uchange --kebab-name add-user-auth --type feat
```

Allowed values follow Conventional Commits v1.0.0: `feat`, `fix`, `build`, `chore`, `ci`, `docs`, `perf`, `refactor`, `revert`, `style`, `test`.

`scope:` and `breaking:` are written into `change.md` frontmatter later by the agent when the Construction section is authored, not at `uchange` time. They flow into `upr` automatically -- the PR title and pre-squash commit subject follow the template `<type>[(<scope>)][!]: <change_title>[ [<issue_id>]]`.
