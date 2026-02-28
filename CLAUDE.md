# Agents instructions

## Naming conventions

| Category                | Convention    | Example                                |
|-------------------------|---------------|----------------------------------------|
| Specs file/folder names | kebab-case    | `spec-impact.md`, `init-project/`      |
| Entity names in specs   | Title Case    | `Human`, `External System`, `AI Agent` |
| Gherkin scenarious      | Sentence case | `User registration`, `Email delivery`  |
| Descriptive text        | Sentence case | `Sends transactional emails`           |
| Section headers         | Sentence case | `## Specifications impact`             |

<!-- uspecs:begin -->

## Execution instructions

When a request starts with one of the keywords below, you must read the corresponding file and follow the rules described there:

- uchange: create a change request following rules from `uspecs/u/actn-uchange.md`
- uarchive, uimpl, usync, udecs, uhow, upr: perform action described in `uspecs/u/actn-{keyword}.md`

Use files from `./uspecs/u` as an initial reference when user mentions uspecs

<!-- uspecs:end -->
