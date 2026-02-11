# Implementation plan: Rename udec command to udecs

## Construction

- [x] rename: [u/actn-udecs.md](../../../../u/actn-udecs.md) -> u/actn-udecs.md
  - update: line 12 - replace `dec.md` with `Decision File` (use artifact name, not filename)
  - update: line 22 - `tmpl-dec.md` -> `tmpl-decs.md`
  - update: line 36 - `uspecs-dec` -> `uspecs-decs`
  - update: line 38 - `uspecs-dec` -> `uspecs-decs`
- [x] rename: [u/templates/tmpl-decs.md](../../../../u/templates/tmpl-decs.md) -> u/templates/tmpl-decs.md
- [x] update: [u/conf.md](../../../../u/conf.md)
  - update: line 34 - `dec.md` -> `decs.md`
- [x] rename: [prod/softeng/decs.feature](../../../../specs/prod/softeng/decs.feature) -> prod/softeng/decs.feature
  - update: line 10 - `uspecs-dec` -> `uspecs-decs`
  - update: line 12 - `uspecs-dec` -> `uspecs-decs`
- [x] update: [AGENTS.md](../../../../../AGENTS.md)
  - update: line 22 - `udec` -> `udecs`, `actn-udec.md` -> `actn-udecs.md`
- [x] update: [CLAUDE.md](../../../../../CLAUDE.md)
  - update: line 22 - `udec` -> `udecs`, `actn-udec.md` -> `actn-udecs.md`
