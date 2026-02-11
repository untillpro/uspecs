# Implementation plan: Reorganize u folder naming

## Construction

### Rename action files

- [x] rename: [u/actn-uchange.md](../../../../u/actn-uchange.md) <- actn-changes.md
- [x] rename: [u/actn-udec.md](../../../../u/actn-udec.md) <- actn-dec.md
- [x] rename: [u/actn-uhow.md](../../../../u/actn-uhow.md) <- actn-how.md
- [x] rename: [u/actn-uimpl.md](../../../../u/actn-uimpl.md) <- actn-impl.md
- [x] rename: [u/actn-usync.md](../../../../u/actn-usync.md) <- actn-sync.md

### Move and rename template files into u/templates/

- [x] move: [u/templates/tmpl-dec.md](../../../../u/templates/tmpl-dec.md) <- u/templates-dec.md
- [x] move: [u/templates/tmpl-how.md](../../../../u/templates/tmpl-how.md) <- u/templates-how.md
- [x] move: [u/templates/tmpl-td.md](../../../../u/templates/tmpl-td.md) <- u/templates-td.md

### Split templates.md into u/templates/

- [x] create: [u/templates/tmpl-change.md](../../../../u/templates/tmpl-change.md)
  - add: Change File Template 1 section from templates.md
- [x] create: [u/templates/tmpl-fd.md](../../../../u/templates/tmpl-fd.md)
  - add: Functional Design Specifications section from templates.md (Scenarios File template, Requirements File template)
- [x] delete: u/templates.md

### Update cross-references

- [x] update: [AGENTS.md](../../../../../AGENTS.md)
  - update: triggering instructions to use new actn-* file names
- [x] update: [CLAUDE.md](../../../../../CLAUDE.md)
  - update: triggering instructions to use new actn-* file names
- [x] update: [u/conf.md](../../../../u/conf.md)
  - remove: $templates and $templates_td parameters
  - add: $templates_folder: uspecs/u/templates
- [x] update: [u/actn-uchange.md](../../../../u/actn-uchange.md)
  - update: `uspecs/u/templates.md` to `$templates_folder/tmpl-change.md`
- [x] update: [u/actn-udec.md](../../../../u/actn-udec.md)
  - update: `uspecs/u/templates-dec.md` to `$templates_folder/tmpl-dec.md`
- [x] update: [u/actn-uhow.md](../../../../u/actn-uhow.md)
  - update: `uspecs/u/templates-how.md` to `$templates_folder/tmpl-how.md`
  - update: `templates-td.md` to `tmpl-td.md` (in Gherkin Examples table)
- [x] update: [u/actn-uimpl.md](../../../../u/actn-uimpl.md)
  - update: `$templates` to `$templates_folder/tmpl-fd.md`
  - update: `$templates_td` to `$templates_folder/tmpl-td.md`
- [x] update: [u/templates/tmpl-how.md](../../../../u/templates/tmpl-how.md)
  - update: `u/actn-how.md` to `u/actn-uhow.md`
  - update: `uspecs/u/templates-td.md` to `$templates_folder/tmpl-td.md`
- [x] update: [specs/prod/softeng/how.feature](../../../../specs/prod/softeng/how.feature)
  - update: `templates-td.md` to `tmpl-td.md`
- [x] update: [specs/prod/softeng/softeng--arch.md](../../../../specs/prod/softeng/softeng--arch.md)
  - update: actn-changes.md to actn-uchange.md in sequence diagram
  - update: actn-impl.md to actn-uimpl.md in sequence diagram

### Standardize headings

Action files use `# Action:` (singular) or `# Actions:` (plural) pattern. Template files use `# Template:` or `# Templates:` pattern.

- [x] update: [u/actn-uchange.md](../../../../u/actn-uchange.md)
  - heading: `# Actions: Changes management`
- [x] update: [u/actn-udec.md](../../../../u/actn-udec.md)
  - heading: `# Action: Change Request clarification`
- [x] update: [u/actn-uhow.md](../../../../u/actn-uhow.md)
  - heading: `# Action: Implementation approach`
- [x] update: [u/actn-uimpl.md](../../../../u/actn-uimpl.md)
  - heading: `# Action: Change request implementation`
- [x] update: [u/actn-usync.md](../../../../u/actn-usync.md)
  - heading: `# Action: Sync Implementation Plan with actual modifications`
- [x] update: [u/templates/tmpl-change.md](../../../../u/templates/tmpl-change.md)
  - heading: `# Templates: Change File`
- [x] update: [u/templates/tmpl-fd.md](../../../../u/templates/tmpl-fd.md)
  - heading: `# Templates: Functional Design`
- [x] update: [u/templates/tmpl-td.md](../../../../u/templates/tmpl-td.md)
  - heading: `# Templates: Technical Design`
