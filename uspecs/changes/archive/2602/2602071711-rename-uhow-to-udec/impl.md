# Implementation: Rename uhow to udec

## Functional design

- [x] update: [softeng/dec.feature](../../../../specs/prod/softeng/dec.feature)
  - update: uspecs-how -> uspecs-dec, How File -> Decision File
  - rename: `git mv` to `dec.feature` (after content update)

## Construction

- [x] update: [uspecs/u/actn-dec.md](../../../../u/actn-dec.md)
  - update: uhow -> udec, uspecs-how -> uspecs-dec, How File -> Decision File, how.md -> dec.md, templates-how.md -> templates-dec.md
  - rename: `git mv` to `actn-dec.md`
- [x] update: [uspecs/u/templates-dec.md](../../../../u/templates-dec.md)
  - update: How File -> Decision File, How: -> Decisions:
  - rename: `git mv` to `templates-dec.md`
- [x] update: [uspecs/u/conf.md](../../../../u/conf.md)
  - update: How File -> Decision File, how.md -> dec.md
- [x] update: [AGENTS.md](../../../../../AGENTS.md)
  - update: uhow -> udec, actn-how.md -> actn-dec.md
- [x] update: [CLAUDE.md](../../../../../CLAUDE.md)
  - update: uhow -> udec, actn-how.md -> actn-dec.md
- [x] update: [2602051817-uhow-top-uncertainties/impl.md](../../../2602051817-uhow-top-uncertainties/impl.md)
  - update: broken relative links (how.feature -> dec.feature, actn-how.md -> actn-dec.md, templates-how.md -> templates-dec.md)
